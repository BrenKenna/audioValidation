# login
ssh -i ~/.ssh/repKey.pem ec2-user@34.244.54.148


# Install terraform etc
sudo su
yum update -y
yum install -y yum-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
yum -y install terraform
yum update -y 


# Setup
mkdir ~/terraform && cd ~/terraform
terraform init


# Plan resources
terraform plan


# Create resources
terraform apply
