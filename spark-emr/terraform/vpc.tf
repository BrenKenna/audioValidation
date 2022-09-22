#################################################
#################################################
# 
# Configure VPC, Subnets, IGW & Routing
#
#  No consideration for worker nat yet
# 
#################################################
#################################################

##########################
##########################
# 
# VPC, Subnets & IGW
# 
##########################
##########################

# Create VPC
resource "aws_vpc" "clusterVPC" {
    cidr_block = var.cluster-network.cidrBlock
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
        Name = "${var.cluster-network.vpcName}"
    }
}

# Configure head node subnet
resource "aws_subnet" "headnode_subnet" {
    vpc_id = aws_vpc.clusterVPC.id
    cidr_block = var.cluster-network.az1_subnets.head
    availability_zone = var.cluster-network.az1_subnets.availZone
    map_public_ip_on_launch = true
    tags = {
        Name = "headnode-subnet"
    }
    depends_on = [ aws_vpc.clusterVPC ]
}

# Configure worker node subnet
resource "aws_subnet" "workernode_subnet" {
    vpc_id = aws_vpc.clusterVPC.id
    cidr_block = var.cluster-network.az1_subnets.worker
    availability_zone = var.cluster-network.az1_subnets.availZone
    map_public_ip_on_launch = true
    tags = {
        Name = "workernode-subnet"
    }
    depends_on = [ aws_vpc.clusterVPC ]
}

# Internet gateway
resource "aws_internet_gateway" "cluster-igw" {
    vpc_id = aws_vpc.clusterVPC.id
    tags = {
        Name = "${var.cluster-network.igw_name}"
    }
    depends_on = [ aws_subnet.workernode_subnet, aws_subnet.headnode_subnet ]
}

##########################
##########################
# 
# Routes
# 
##########################
##########################

# Create route table
resource "aws_route_table" "cluster-rtb-pub" {
    vpc_id = aws_vpc.clusterVPC.id
    tags = {
        Name = "cluster-rtb-pub"
    }
    depends_on = [ aws_internet_gateway.cluster-igw ]
}

# Route out to any IP via gateway
resource "aws_route" "cluster-igw-route" {
    route_table_id = aws_route_table.cluster-rtb-pub.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cluster-igw.id
    depends_on = [ aws_route_table.cluster-rtb-pub ]
}

# Associate the head & worker node subnets to the route table
resource "aws_route_table_association" "cluster-rta-head" {
    subnet_id = "${aws_subnet.headnode_subnet.id}"
    route_table_id = "${aws_route_table.cluster-rtb-pub.id}"
    depends_on = [ aws_route.cluster-igw-route ]
}
resource "aws_route_table_association" "cluster-rta-worker" {
    subnet_id = "${aws_subnet.workernode_subnet.id}"
    route_table_id = "${aws_route_table.cluster-rtb-pub.id}"
    depends_on = [ aws_route.cluster-igw-route ]
}