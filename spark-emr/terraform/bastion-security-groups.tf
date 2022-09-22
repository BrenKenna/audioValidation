######################################################
######################################################
# 
# Security Groups for Head & Worker
#   Long term be nice to see how to lockdown
# 
######################################################
######################################################

# Security group for headnode
resource "aws_security_group" "bastion-sg" {
    name = "bastion-sg"
    description = "Security group for bastion node"
    vpc_id = "${aws_vpc.clusterVPC.id}"
    revoke_rules_on_delete = true
    tags = {
        name = "bastion-sg"
    }

    # Allow external ssh traffic
    ingress {
        from_port = 22
        to_port = 22
        protocol = "TCP"
        cidr_blocks = [ "0.0.0.0/0" ]
    }

    # Allow external http traffic
    ingress {
        from_port = 80
        to_port = 80
        protocol = "TCP"
        cidr_blocks = [ "0.0.0.0/0" ]
    }

    # Allow external https traffic
    ingress {
        from_port = 443
        to_port = 443
        protocol = "TCP"
        cidr_blocks = [ "0.0.0.0/0" ]
    }

    # Allow outbound 
    egress {
        from_port = "0"
        to_port = "0"
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
}