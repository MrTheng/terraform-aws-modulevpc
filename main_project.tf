#Terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
#Provider
provider "aws" {
  region = "us-east-1"
}
### Create VPC and EC2
module "vpc" {
  source = "./vpc"
  user_data = file("userdata.sh")
  vpc_cidr_block    = "10.0.0.0/16"
  private_subnet    = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24", "10.0.5.0/24"]
  public_subnet     = ["10.0.6.0/24", "10.0.7.0/24", "10.0.8.0/24", "10.0.9.0/24", "10.0.10.0/24"]
  availability_zone = ["us-east-1a", "us-east-1b", "us-east-1c",  "us-east-1d", "us-east-1e"]
}

  
#module "ec2_instances_private" {
#  source  = "terraform-aws-modules/ec2-instance/aws"
#  version = "4.3.0"
#
#  count = 5
#  name  = "My-web-server"
#  key_name                = var.key_pair 
#  ami                     = var.vpc_ami
#  instance_type           = var.instance_type
#  vpc_security_group_ids  = [module.vpc.default_security_group_id]
#  subnet_id               = element(var.private_subnet, count.index)
#
#  tags = {
#    Name = "my-ec2-private${count.index}"
#  }
#}
