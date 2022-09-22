######################################################
######################################################
# 
# Security Groups for Head & Worker
#   Long term be nice to see how to lockdown
# 
######################################################
######################################################

# Security group for headnode
resource "aws_security_group" "cluster-headnode-sg" {
    name = "cluster-headnode-sg"
    description = "Security group for cluster headnode"
    vpc_id = "${aws_vpc.clusterVPC.id}"
    revoke_rules_on_delete = true
    tags = {
        name = "cluster-headnode-sg"
    }

    # Allow internal traffic, could be configured better
    ingress {
        from_port = "0"
        to_port = "0"
        protocol = "-1"
        cidr_blocks = [ "${var.cluster-network.cidrBlock}" ]
    }

    # Allow bastion ssh traffic
    ingress {
        from_port = 22
        to_port = 22
        protocol = "TCP"
        cidr_blocks = [ "${var.cluster-network.az1_subnets.bastionCidrBlock}" ]
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


#################################
#################################
# 
# Worker node
# 
#################################
#################################


# Worker node
resource "aws_security_group" "cluster-workernode-sg" {
    name = "cluster-workernode-sg"
    description = "Security group for cluster worker node"
    vpc_id = "${aws_vpc.clusterVPC.id}"
    tags = {
        name = "cluster-workernode-sg"
    }
 
    # Allow internal traffic, could be configured better
    ingress {
        from_port = "0"
        to_port = "0"
        protocol = "-1"
        cidr_blocks = [ "${var.cluster-network.cidrBlock}" ]
    }
 
    # Allow ssh traffic from bastion
    ingress {
        from_port = 22
        to_port = 22
        protocol = "TCP"
        cidr_blocks = [ "${var.cluster-network.az1_subnets.bastionCidrBlock}" ]
    }

    # Outbound
    egress {
        from_port   = "0"
        to_port     = "0"
        protocol    = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
}