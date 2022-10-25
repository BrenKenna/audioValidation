resource "aws_instance" "tf-test" {
    ami = "ami-096272de2ef1e474c"
    instance_type = "t2.micro"
    key_name = "repKey"
    iam_instance_profile = "${aws_iam_instance_profile.instanceProfileRole}"
    security_groups = [ "sg-0666a1ed701efc5cf" ]
    associate_public_ip_address = true
    subnet_id = "subnet-0b506209d9b6a4159"
    tags = {
        Name = "tf-test-3"
    }
}