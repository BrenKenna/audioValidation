###################################################
###################################################
#
# Module to hold common variables
#
# Gradually build on the tutorial and see how
#  to put worker nodes on private network
# 
###################################################
###################################################

# Network config as object
variable "cluster-network" {
    description = "Object to hold network configuration for the cluster"
    type = object({

        # Shared VPC settings
        vpcName = string
        cidrBlock = string
        region = string
        igw_name = string

        # One network for head node
        #   another for workers
        az1_subnets = object({
            availZone = string 
            bastionCidrBlock = string
            clusterCidrBlock = string
        })

        /*

        # Notion of high avail could be nice
        #   ignore for now though
        az2_subnets = object({
            availZone = string 
            bastionCidrBlock = string
            clusterCidrBlock = string
        })
        */
    })

    # Values for object
    default = {
        cidrBlock = "192.168.0.0/16"
        region = "eu-west-1"
        vpcName = "cluster-VPC"
        igw_name = "clusterIGW"
    
        # For eu-west-1a
        az1_subnets = {
            "availZone": "eu-west-1a",
            "bastionCidrBlock": "192.168.1.0/24",
            "clusterCidrBlock": "192.168.2.0/24"
        }

        /*
        az2_subnets = {
            "availZone": "eu-west-1b",
            "bastionCidrBlock": "192.168.3.0/24",
            "clusterCidrBlock": "192.168.4.0/24"
        }
        */
    }
}


# General config
variable "cluster-general" {
    description = "Object to hold general configurations for the cluster"
    type = object({
        bucketName = string
        bucketACL = string
        region = string
        key = string
        loggingUri = string
        amiDebug = string
    })

    default = {
        bucketName = "spark-cluster-tf"
        bucketACL = "private"
        region = "eu-west-1"
        key = "emrKey"
        loggingUri = "s3://bk-spark-cluster-tf/spark/"
        amiDebug = "ami-05890c70635a7423c"
    }
}

# Provider credentials
variable "auth-tf" {
    description = "Credentials provider"
    type = object({
        roleArn = string
        sessionName = string
    })

    default = {
        roleArn = "arn:aws:iam::986224559876:role/Custom-Ec2-Role"
        sessionName = "Spark-Terraform"
    }
}

# Instance types
variable "cluster-instances" {
    description = "Object to hold cluster instance types"
    type = object({

        # Instance type
        headType = string
        workerType = string
        taskType = string

        # Cluster size
        headCount = number
        workerCount = number
        taskCount = number
    })

    default = {
        headType = "c5a.16xlarge"
        workerType = "m5.4xlarge"
        taskType = "m5a.8xlarge"
        headCount = 1 # 3
        workerCount = 3
        taskCount = 3
    }
}