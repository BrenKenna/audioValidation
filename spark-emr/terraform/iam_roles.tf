##########################################################
##########################################################
# 
# IAM Roles
# 
# Console based NACL quite open for simple cluster
# 
# https://intothedepthsofdataengineering.wordpress.com/2017/11/19/terraforming-a-spark-cluster-on-amazon/
#
# <<span data-mce-type="bookmark" id="mce_SELREST_start" data-mce-style="overflow:hidden;line-height:0" style="overflow:hidden;line-height:0" >﻿</span>
# 
##########################################################
##########################################################


###############################################
###############################################
# 
# Create Policy & Role
# 
###############################################
###############################################

# Create cluster role
resource "aws_iam_role" "sparkClusterRole" {
    name = "sparkClusterRole"
    tags = {
        Name = "sparkClusterRole"
    }
    assume_role_policy = <<-EOF
        {
        "Version": "2008-10-17",
        "Statement": [
            {
                "Sid": "",
                "Effect": "Allow",
                "Principal": {
                    "Service": "elasticmapreduce.amazonaws.com"
                },
                "Action": "sts:AssumeRole"
            }
        ]
    }
    EOF
}

# Cluster profile
resource "aws_iam_role" "sparkClusterRole-profile" {
    name = "sparkClusterRole-profile"
    tags = {
        Name = "sparkClusterRole-profile"
    }
    assume_role_policy = <<-EOF
        {
            "Version": "2008-10-17",
            "Statement": [
                {
                    "Sid": "",
                    "Effect": "Allow",
                    "Principal": {
                        "Service": "ec2.amazonaws.com"
                    },
                    "Action": "sts:AssumeRole"
                }
            ]
        }
    EOF
}


###############################################
###############################################
#
# Attach Polices
#
###############################################
###############################################

# EMR Service
resource "aws_iam_role_policy_attachment" "emrService-pol-attach" {
   role = "${aws_iam_role.sparkClusterRole.id}"
   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceRole"
   depends_on = [ aws_iam_role.sparkClusterRole, aws_iam_role.sparkClusterRole-profile ]
}

# EC2
resource "aws_iam_role_policy_attachment" "profile-pol-attach" {
   role = "${aws_iam_role.sparkClusterRole-profile.id}"
   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceforEC2Role"
   depends_on = [ aws_iam_role.sparkClusterRole, aws_iam_role.sparkClusterRole-profile ]
}


resource "aws_iam_instance_profile" "spark-emr-profile" {
   name = "spark-emr-profile"
   role = "${aws_iam_role.sparkClusterRole-profile.name}"
}