####################################################################
####################################################################
# 
# Network access control list & SG
# 
# Console based NACL quite open for simple cluster
# 
# https://intothedepthsofdataengineering.wordpress.com/2017/11/19/terraforming-a-spark-cluster-on-amazon/
# 
####################################################################
####################################################################


######################################################
######################################################
# 
# Network Access Control List for Head & Worker
#   Long term be nice to see how to lockdown
# 
######################################################
######################################################

# Create nacl
resource "aws_network_acl" "cluster-nacl" {
    vpc_id = aws_vpc.clusterVPC.id
    subnet_ids = [ aws_subnet.headnode_subnet.id, aws_subnet.workernode_subnet.id ]
    tags = {
        Name = "cluster-nacl"
    }
    depends_on = [ aws_subnet.headnode_subnet, aws_subnet.workernode_subnet ]
}

# Add open rule
resource "aws_network_acl_rule" "inbound-cluster" {
    network_acl_id = aws_network_acl.cluster-nacl.id
    rule_number = 100
    egress = false
    protocol = "-1"
    rule_action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = -1
    to_port = -1
    depends_on = [ aws_network_acl.cluster-nacl ]
}
resource "aws_network_acl_rule" "outbound-cluster" {
    network_acl_id = aws_network_acl.cluster-nacl.id
    rule_number = 100
    egress = true
    protocol = "-1"
    rule_action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = -1
    to_port = -1
    depends_on = [ aws_network_acl.cluster-nacl ]
}


######################################################
######################################################
# 
# Security Groups for Head & Worker
#   Long term be nice to see how to lockdown
# 
######################################################
######################################################

# Security group for headnode
resource "aws_security_group" "headnode-sg" {
    name = "headnode-sg"
    description = "Security group for head node"
    vpc_id = "${aws_vpc.clusterVPC.id}"
    revoke_rules_on_delete = true
    tags = {
        name = "headnode-sg"
    }
 
    # Allow communication between nodes in the VPC
    ingress {
        from_port = "0"
        to_port = "0"
        protocol = "-1"
        cidr_blocks = [ "${var.cluster-network.cidrBlock}" ]
    }
    /*
    Blocked this given the above, not sure why
    ingress {
        from_port = "8443"
        to_port = "8443"
        protocol = "TCP"
    }
    */

    /*
        External traffic rules
    */
    # Allow external ssh traffic
    ingress {
        from_port = 22
        to_port = 22
        protocol = "TCP"
        cidr_blocks = [ "0.0.0.0/0" ] # Should really be own IP/CIDR of default vpc
    }

    # Yarn
    ingress {
        from_port = 8088
        to_port = 8088
        protocol = "TCP"
        cidr_blocks = [ "${var.cluster-network.cidrBlock}" ]
    }
 
    # Spark History
    ingress {
        from_port = 18080
        to_port = 18080
        protocol = "TCP"
        cidr_blocks = [ "${var.cluster-network.cidrBlock}" ]
    }
 
    # Zeppelin
    ingress {
        from_port = 8890
        to_port = 8890
        protocol = "TCP"
        cidr_blocks = [ "${var.cluster-network.cidrBlock}" ]
    }
 
    # Spark UI
    ingress {
        from_port = 4040
        to_port = 4040
        protocol = "TCP"
        cidr_blocks = [ "${var.cluster-network.cidrBlock}" ]
    }

    # Hadoop name node
    ingress {
        from_port = 50070
        to_port = 50070
        protocol = "TCP"
        cidr_blocks = [ "${var.cluster-network.cidrBlock}" ]
    }

    # Spark history
    ingress {
        from_port = 18080
        to_port = 18080
        protocol = "TCP"
        cidr_blocks = [ "${var.cluster-network.cidrBlock}" ]
    }
 
    # Ganglia
    ingress {
        from_port = 80
        to_port = 80
        protocol = "TCP"
        cidr_blocks = [ "${var.cluster-network.cidrBlock}" ]
    }
 
    # Hue
    ingress {
        from_port = 8888
        to_port = 8888
        protocol = "TCP"
        cidr_blocks = [ "${var.cluster-network.cidrBlock}" ]
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
resource "aws_security_group" "workernode-sg" {
    name = "workernode-sg"
    description = "Security group for worker node"
    vpc_id = "${aws_vpc.clusterVPC.id}"
    tags = {
        name = "workernode-sg"
    }
 
    # Allow internal traffic, could be configured better
    ingress {
        from_port = "0"
        to_port = "0"
        protocol = "-1"
        cidr_blocks = [ "${var.cluster-network.cidrBlock}" ]
    }
 
    /*
    Similar to the head node
    ingress {
        from_port = "8443"
        to_port = "8443"
        protocol = "TCP"
    }
    */
    # Allow internal ssh traffice
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