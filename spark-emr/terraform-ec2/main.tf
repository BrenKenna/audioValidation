resource "aws_instance" "tf-test" {
    ami = "ami-06dbf82cf78dccd44"
    instance_type = "t2.micro"
    key_name = "emr-key"
    security_groups = [ "sg-0fab80bff4bd66aac" ]
    associate_public_ip_address = true
    subnet_id = "subnet-0b506209d9b6a4159"
    tags = {
        Name = "tf-test-3"
    }
}