#################################################
#################################################
# 
# Configure VPC, Subnets & Routing
#
#################################################
#################################################

####################################
####################################
# 
# VPC & Subnets
# 
####################################
####################################

# Create VPC
resource "aws_vpc" "clusterVPC" {
    cidr_block = var.cluster-network.cidrBlock
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
        Name = "${var.cluster-network.vpcName}"
    }
}

# Configure bastion node subnet
resource "aws_subnet" "bastion_subnet" {
    vpc_id = aws_vpc.clusterVPC.id
    cidr_block = var.cluster-network.az1_subnets.bastionCidrBlock
    availability_zone = "eu-west-1b"
    map_public_ip_on_launch = true
    tags = {
        Name = "bastion-subnet"
    }
    depends_on = [ aws_vpc.clusterVPC ]
}

# Configure cluster subnet
resource "aws_subnet" "cluster_subnet" {
    vpc_id = aws_vpc.clusterVPC.id
    cidr_block = var.cluster-network.az1_subnets.clusterCidrBlock
    availability_zone = var.cluster-network.az1_subnets.availZone
    map_public_ip_on_launch = false
    tags = {
        Name = "cluster-subnet"
    }
    depends_on = [ aws_vpc.clusterVPC ]
}