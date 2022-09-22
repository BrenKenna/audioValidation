#############################################
#############################################
# 
# Routing Tables
# 
#############################################
#############################################

###########################
###########################
# 
# Public
# 
###########################
###########################

# Create route table
resource "aws_route_table" "bastion-rtb-pub" {
    vpc_id = aws_vpc.clusterVPC.id
    tags = {
        Name = "bastion-rtb"
    }
    depends_on = [ aws_internet_gateway.igw-bastion ]
}

# Route out to any IP via gateway
resource "aws_route" "bastion-igw-route" {
    route_table_id = aws_route_table.bastion-rtb-pub.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-bastion.id
    depends_on = [ aws_route_table.bastion-rtb-pub ]
}

# Associate the bastion subnet to route table
resource "aws_route_table_association" "cluster-rta" {
    subnet_id = "${aws_subnet.bastion_subnet.id}"
    route_table_id = "${aws_route_table.bastion-rtb-pub.id}"
    depends_on = [ aws_route.bastion-igw-route ]
}


###########################
###########################
# 
# Private
# 
###########################
###########################

# Create route table
resource "aws_route_table" "cluster-rtb-priv" {
    vpc_id = aws_vpc.clusterVPC.id
    tags = {
        Name = "cluster-rtb-priv"
    }
    depends_on = [ aws_nat_gateway.nat-cluster ]
}

# Route out to any IP via gateway
resource "aws_route" "cluster-nat-route" {
    route_table_id = aws_route_table.cluster-rtb-priv.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat-cluster.id
    depends_on = [ aws_route_table.cluster-rtb-priv ]
}

# Associate the bastion subnet to route table
resource "aws_route_table_association" "cluster-rta" {
    subnet_id = "${aws_subnet.bastion_subnet.id}"
    route_table_id = "${aws_route_table.bastion-rtb-pub.id}"
    depends_on = [ aws_route.bastion-igw-route ]
}
