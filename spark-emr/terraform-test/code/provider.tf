provider "aws" {
    region = "eu-west-1"
    assume_role {
        role_arn = "arn:aws:iam::986224559876:role/Custom-Ec2-Role"
        session_name = "EC2-Test"
    }
}