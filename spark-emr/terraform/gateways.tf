#################################################
#################################################
# 
# Configure VPC Gateways
# 
#################################################
#################################################


# Internet gateway
resource "aws_internet_gateway" "igw-bastion" {
    vpc_id = aws_vpc.clusterVPC.id
    tags = {
        Name = "${var.cluster-network.igw_name}"
    }
    depends_on = [
        aws_subnet.bastion_subnet,
        aws_subnet.cluster_subnet
    ]
}


# NAT gateway for cluster
resource "aws_eip" "eip-cluster-nat" {
    vpc = true
}
resource "aws_nat_gateway" "nat-cluster" {
    allocation_id = aws_eip.eip-cluster-nat.id
    subnet_id = aws_subnet.bastion_subnet.id
    tags = {
        Name = "nat-cluster"
    }
}