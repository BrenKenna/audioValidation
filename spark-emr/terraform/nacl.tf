######################################################
######################################################
# 
# Network Access Control List for Head & Worker
#   Long term be nice to see how to lockdown
# 
######################################################
######################################################


#########################################
#########################################
#
# 1). Cluster NACL
#
#########################################
#########################################

# Create nacl
resource "aws_network_acl" "cluster-nacl" {
    vpc_id = aws_vpc.clusterVPC.id
    subnet_ids = [ aws_subnet.cluster_subnet.id ]
    tags = {
        Name = "cluster-nacl"
    }
    depends_on = [ aws_subnet.bastion_subnet, aws_subnet.cluster_subnet ]
}

############################
############################
#
# SSH
#
############################
############################


# Allow in/out SSH
resource "aws_network_acl_rule" "inbound-ssh-cluster" {
    network_acl_id = aws_network_acl.cluster-nacl.id
    rule_number = 100
    egress = false
    protocol = "tcp"
    rule_action = "allow"
    cidr_block = "${var.cluster-network.cidrBlock}"
    from_port = 22
    to_port = 22
    depends_on = [ aws_network_acl.cluster-nacl ]
}
resource "aws_network_acl_rule" "outbound-ssh-cluster" {
    network_acl_id = aws_network_acl.cluster-nacl.id
    rule_number = 100
    egress = true
    protocol = "tcp"
    rule_action = "allow"
    cidr_block = "${var.cluster-network.cidrBlock}"
    from_port = 22
    to_port = 22
    depends_on = [ aws_network_acl.cluster-nacl ]
}


############################
############################
#
# HTTP - Covers Ganglia
#
############################
############################

# Allow in/out HTTP
resource "aws_network_acl_rule" "inbound-http-cluster" {
    network_acl_id = aws_network_acl.cluster-nacl.id
    rule_number = 101
    egress = false
    protocol = "tcp"
    rule_action = "allow"
    cidr_block = "0.0.0.9/0"
    from_port = 80
    to_port = 80
    depends_on = [ aws_network_acl.cluster-nacl ]
}
resource "aws_network_acl_rule" "outbound-http-cluster" {
    network_acl_id = aws_network_acl.cluster-nacl.id
    rule_number = 101
    egress = true
    protocol = "tcp"
    rule_action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 80
    to_port = 80
    depends_on = [ aws_network_acl.cluster-nacl ]
}


############################
############################
#
# HTTPS - Covers NAT
#
############################
############################

# Allow outbound HTTPs
resource "aws_network_acl_rule" "outbound-https-cluster" {
    network_acl_id = aws_network_acl.cluster-nacl.id
    rule_number = 102
    egress = true
    protocol = "tcp"
    rule_action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 443
    to_port = 443
    depends_on = [ aws_network_acl.cluster-nacl ]
}


############################
############################
#
# Ephemeral
# - Covers 4040-> 18080
#
############################
############################

# Allow in/out ephem
resource "aws_network_acl_rule" "inbound-ephem-cluster" {
    network_acl_id = aws_network_acl.cluster-nacl.id
    rule_number = 103
    egress = false
    protocol = "tcp"
    rule_action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 1024
    to_port = 65535
    depends_on = [ aws_network_acl.cluster-nacl ]
}
resource "aws_network_acl_rule" "outbound-ephem-cluster" {
    network_acl_id = aws_network_acl.cluster-nacl.id
    rule_number = 103
    egress = true
    protocol = "tcp"
    rule_action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 1024
    to_port = 65535
    depends_on = [ aws_network_acl.cluster-nacl ]
}


############################
############################
#
# Ping Internet Access
#
############################
############################

# Allow in/out ping
resource "aws_network_acl_rule" "inbound-ping-cluster" {
    network_acl_id = aws_network_acl.cluster-nacl.id
    rule_number = 104
    egress = false
    protocol = "icmp"
    rule_action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = -1
    to_port = -1
    icmp_type = -1
    icmp_code = -1
    depends_on = [ aws_network_acl.cluster-nacl ]
}
resource "aws_network_acl_rule" "outbound-ping-cluster" {
    network_acl_id = aws_network_acl.cluster-nacl.id
    rule_number = 104
    egress = true
    protocol = "icmp"
    rule_action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = -1
    to_port = -1
    icmp_type = -1
    icmp_code = -1
    depends_on = [ aws_network_acl.cluster-nacl ]
}


#########################################
#########################################
#
# 2). Bastion NACL
#
#########################################
#########################################

# Create nacl
resource "aws_network_acl" "bastion-nacl" {
    vpc_id = aws_vpc.clusterVPC.id
    subnet_ids = [ aws_subnet.bastion_subnet.id ]
    tags = {
        Name = "bastion-nacl"
    }
    depends_on = [ aws_subnet.bastion_subnet, aws_subnet.cluster_subnet ]
}

############################
############################
#
# SSH
#
############################
############################


# Allow in/out SSH
resource "aws_network_acl_rule" "inbound-ssh-bastion" {
    network_acl_id = aws_network_acl.bastion-nacl.id
    rule_number = 100
    egress = false
    protocol = "tcp"
    rule_action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 22
    to_port = 22
    depends_on = [ aws_network_acl.bastion-nacl ]
}
resource "aws_network_acl_rule" "outbound-ssh-bastion" {
    network_acl_id = aws_network_acl.bastion-nacl.id
    rule_number = 100
    egress = true
    protocol = "tcp"
    rule_action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 22
    to_port = 22
    depends_on = [ aws_network_acl.bastion-nacl ]
}



############################
############################
#
# HTTP - Covers Ganglia
#
############################
############################

# Allow in/out HTTP
resource "aws_network_acl_rule" "inbound-http-bastion" {
    network_acl_id = aws_network_acl.bastion-nacl.id
    rule_number = 101
    egress = false
    protocol = "tcp"
    rule_action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 80
    to_port = 80
    depends_on = [ aws_network_acl.bastion-nacl ]
}
resource "aws_network_acl_rule" "outbound-http-bastion" {
    network_acl_id = aws_network_acl.bastion-nacl.id
    rule_number = 101
    egress = true
    protocol = "tcp"
    rule_action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 80
    to_port = 80
    depends_on = [ aws_network_acl.bastion-nacl ]
}


############################
############################
#
# HTTPS - Covers NAT
#
############################
############################

# Allow in/outbound HTTPs
resource "aws_network_acl_rule" "inbound-https-bastion" {
    network_acl_id = aws_network_acl.bastion-nacl.id
    rule_number = 102
    egress = false
    protocol = "tcp"
    rule_action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 443
    to_port = 443
    depends_on = [ aws_network_acl.bastion-nacl ]
}
resource "aws_network_acl_rule" "outbound-https-bastion" {
    network_acl_id = aws_network_acl.bastion-nacl.id
    rule_number = 102
    egress = true
    protocol = "tcp"
    rule_action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 443
    to_port = 443
    depends_on = [ aws_network_acl.bastion-nacl ]
}


############################
############################
#
# Ephemeral
# - Covers 4040-> 18080
#
############################
############################

# Allow in/out ephem
resource "aws_network_acl_rule" "inbound-ephem-bastion" {
    network_acl_id = aws_network_acl.bastion-nacl.id
    rule_number = 103
    egress = false
    protocol = "tcp"
    rule_action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 1024
    to_port = 65535
    depends_on = [ aws_network_acl.bastion-nacl ]
}
resource "aws_network_acl_rule" "outbound-ephem-bastion" {
    network_acl_id = aws_network_acl.bastion-nacl.id
    rule_number = 103
    egress = true
    protocol = "tcp"
    rule_action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 1024
    to_port = 65535
    depends_on = [ aws_network_acl.bastion-nacl ]
}


############################
############################
#
# Ping Tests
# - Covers 4040-> 18080
#
############################
############################


# Allow in/out ping
resource "aws_network_acl_rule" "inbound-ping-bastion" {
    network_acl_id = aws_network_acl.bastion-nacl.id
    rule_number = 104
    egress = false
    protocol = "icmp"
    rule_action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = -1
    to_port = -1
    icmp_type = -1
    icmp_code = -1
    depends_on = [ aws_network_acl.bastion-nacl ]
}
resource "aws_network_acl_rule" "outbound-ping-bastion" {
    network_acl_id = aws_network_acl.bastion-nacl.id
    rule_number = 104
    egress = true
    protocol = "icmp"
    rule_action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = -1
    to_port = -1
    icmp_type = -1
    icmp_code = -1
    depends_on = [ aws_network_acl.bastion-nacl ]
}