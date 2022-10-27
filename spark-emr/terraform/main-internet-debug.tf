# Bastion
resource "aws_instance" "debugging-bastion-server" {
    ami = "${var.cluster-general.amiDebug}"
    instance_type = "t3.large"
    key_name = "${var.cluster-general.key}"
    security_groups = [ "${aws_security_group.bastion-sg.id}" ]
    associate_public_ip_address = true
    subnet_id = "${aws_subnet.bastion_subnet.id}"
    tags = {
        Name = "bastion-server"
    }
}


# Cluster
resource "aws_instance" "debugging-cluster-server" {
    ami = "${var.cluster-general.amiDebug}"
    instance_type = "t3.large"
    key_name = "${var.cluster-general.key}"
    security_groups = [ "${aws_security_group.bastion-sg.id}" ]
    associate_public_ip_address = false
    subnet_id = "${aws_subnet.cluster_subnet.id}"
    tags = {
        Name = "cluster-server"
    }
}