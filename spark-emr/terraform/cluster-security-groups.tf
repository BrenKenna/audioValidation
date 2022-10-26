###############################################################
###############################################################
# 
# Security Groups for Head/Worker nodes & Service Access
#   Long term be nice to see how to lockdown
# 
###############################################################
###############################################################


###########################################
###########################################
# 
# Headnode
# 
###########################################
###########################################

# Security group for headnode
resource "aws_security_group" "cluster-headnode-sg" {
    name = "ElasticMapReduce-Master-Private"
    description = "Security group for cluster headnode"
    vpc_id = "${aws_vpc.clusterVPC.id}"
    revoke_rules_on_delete = true
    tags = {
        Name = "ElasticMapReduce-Master-Private"
    }
    lifecycle {
        ignore_changes = [ingress, egress]
    }

    # Allow internal traffic, could be configured better
    ingress {
        from_port = "0"
        to_port = "0"
        protocol = "-1"
        cidr_blocks = [ "${var.cluster-network.cidrBlock}" ]
    }

    # Allow vpc ssh traffic
    ingress {
        from_port = 22
        to_port = 22
        protocol = "TCP"
        cidr_blocks = [ "${var.cluster-network.cidrBlock}" ]
    }

    # Yarn from bastion
    ingress {
        from_port = 8088
        to_port = 8088
        protocol = "TCP"
        cidr_blocks = [ "${var.cluster-network.az1_subnets.bastionCidrBlock}" ]
    }
 
    # Spark History from bastion
    ingress {
        from_port = 18080
        to_port = 18080
        protocol = "TCP"
        cidr_blocks = [ "${var.cluster-network.az1_subnets.bastionCidrBlock}" ]
    }
 
    # Zeppelin from bastion
    ingress {
        from_port = 8890
        to_port = 8890
        protocol = "TCP"
        cidr_blocks = [ "${var.cluster-network.az1_subnets.bastionCidrBlock}" ]
    }
 
    # Spark UI from bastion
    ingress {
        from_port = 4040
        to_port = 4040
        protocol = "TCP"
        cidr_blocks = [ "${var.cluster-network.az1_subnets.bastionCidrBlock}" ]
    }

    # Hadoop name node from bastion
    ingress {
        from_port = 50070
        to_port = 50070
        protocol = "TCP"
        cidr_blocks = [ "${var.cluster-network.az1_subnets.bastionCidrBlock}" ]
    }
 
    # Ganglia from bastion
    ingress {
        from_port = 80
        to_port = 80
        protocol = "TCP"
        cidr_blocks = [ "${var.cluster-network.cidrBlock}" ]
    }
 
    # Hue from bastion
    ingress {
        from_port = 8888
        to_port = 8888
        protocol = "TCP"
        cidr_blocks = [ "${var.cluster-network.az1_subnets.bastionCidrBlock}" ]
    }

    # Allow outbound 
    egress {
        from_port = "0"
        to_port = "0"
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
}


###########################################
###########################################
# 
# Service Access SG
# 
###########################################
###########################################

# Create service access security group
resource "aws_security_group" "service-access-sg" {
    name = "ElasticMapReduce-ServiceAccess"
    description = "Service access security group"
    vpc_id = "${aws_vpc.clusterVPC.id}"
    tags = {
        "Name": "ElasticMapReduce-ServiceAccess"
    }
    depends_on = [ aws_security_group.cluster-headnode-sg ]
    lifecycle {
        ignore_changes = [ingress, egress]
    }

    ingress {
        from_port = 9443
        to_port = 9443
        protocol = "TCP"
        cidr_blocks = [ "${var.cluster-network.cidrBlock}" ]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "TCP"
        cidr_blocks = [ "0.0.0.0/0" ] # SG of worker & task nodes
    }

    /*
    egress {
        from_port = 8443
        to_port = 8443
        protocol = "TCP"
        cidr_blocks = [ "${var.cluster-network.cidrBlock}" ]
    }
    */
}


###########################################
###########################################
# 
# Worker node
# 
###########################################
###########################################


# Worker node
resource "aws_security_group" "cluster-workernode-sg" {
    name = "ElasticMapReduce-Slave-Private"
    description = "Security group for cluster worker node"
    vpc_id = "${aws_vpc.clusterVPC.id}"
    tags = {
        Name = "ElasticMapReduce-Slave-Private"
    }
    lifecycle {
        ignore_changes = [ingress, egress]
    }
 
    # Allow internal traffic, could be configured better
    ingress {
        from_port = "0"
        to_port = "0"
        protocol = "-1"
        cidr_blocks = [ "${var.cluster-network.cidrBlock}" ]
    }
 
    # Allow ssh traffic from vpc
    ingress {
        from_port = 22
        to_port = 22
        protocol = "TCP"
        cidr_blocks = [ "${var.cluster-network.cidrBlock}" ]
    }

    # Outbound
    egress {
        from_port   = "0"
        to_port     = "0"
        protocol    = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
}