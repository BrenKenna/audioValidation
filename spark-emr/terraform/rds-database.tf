# Security group
# Worker node
resource "aws_security_group" "publicSG-db" {
    name = "publicSG-db"
    description = "Security group for public DB"
    vpc_id = "${aws_vpc.clusterVPC.id}"
    tags = {
        Name = "publicSG-db"
    }
    lifecycle {
        ignore_changes = [ingress, egress]
    }
    revoke_rules_on_delete = true
 
    # Allow internal traffic, could be configured better
    ingress {
        from_port = "0"
        to_port = "0"
        protocol = "-1"
        cidr_blocks = [ "${var.cluster-network.cidrBlock}" ]
    }
 
    # Allow ssh traffic from anywhere
    ingress {
        from_port = 22
        to_port = 22
        protocol = "TCP"
        cidr_blocks = [ "0.0.0.0/0" ]
    }

    # Allow ssh traffic from vpc
    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "TCP"
        cidr_blocks = [ "0.0.0.0/0" ]
    }

    # Outbound
    egress {
        from_port   = "0"
        to_port     = "0"
        protocol    = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
}


# Public DB
resource "aws_db_instance" "testDB" {
    identifier = "testDB"
    engine = "mysql"
    engine_version = "8.0.28"

    allocated_storage = 40
    storage_type = "gp2"
    instance_class = "db.r6i.2xlarge"

    publicly_accessible = true
    port = 3306
    subnet_ids = "${aws_subnet.bastion_subnet.id}"

    name = "testDB"
    username = "admin"
    password = "D0Ivk5y_Kon6!"
    
    tags = {
        Name = "testDB"
    }
}