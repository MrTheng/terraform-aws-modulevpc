output "vpc" {
    value = aws_vpc.vpc.cidr_block
}

output "public_subnet" {
  value = { for i, v in aws_subnet.public_subnet : format("public_ip%d", i + 1) => v.cidr_block } 
}
output "private_subnet" {
  value = { for i, v in aws_subnet.private_subnet : format("private_ip%d", i + 1) => v.cidr_block }
}
#
#output "webserver" {
#  value = { for i, v in aws_instance.ec2-public : format("web_server%d", i + 1) => v.cidr_block }
#}

