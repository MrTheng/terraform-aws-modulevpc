#Create VPC
resource "aws_vpc" "vpc" {
    cidr_block          = var.vpc_cidr_block
    enable_dns_support  = true

tags = {
    "Name" = "my-vpc"
}
}

#Create Subnet
resource "aws_subnet" "public_subnet" {
    count = length(var.public_subnet)
    vpc_id            = aws_vpc.vpc.id
    cidr_block        = var.public_subnet[count.index]
    availability_zone = var.availability_zone[count.index % length(var.availability_zone)]

  tags = {
    "Name" = "my-public-${var.public_subnet[count.index]}"
  }
}

resource "aws_subnet" "private_subnet" {
    count = length(var.private_subnet)
    vpc_id = aws_vpc.vpc.id
    cidr_block = var.private_subnet[count.index]
    availability_zone = var.availability_zone[count.index % length(var.availability_zone)]

  tags = {
    "Name" = "my-private-${var.private_subnet[count.index]}"
  }
}

#Create IGW & add Route Table for public subnet
resource "aws_internet_gateway" "ig" {
    vpc_id = aws_vpc.vpc.id

    tags = {
      "Name" = "internet gateway"
    }
}
resource "aws_route_table" "rt" {
    vpc_id = aws_vpc.vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.ig.id
    }
    tags = {
      "Name" = "Public-RT"
    }
}
#Association RT to the public subnet
resource "aws_route_table_association" "public_association" {
    for_each = { for k, v in aws_subnet.public_subnet : k => v }
    subnet_id = each.value.id
    route_table_id = aws_route_table.rt.id
}

#Define the security group for public 
resource "aws_security_group" "sg_public" {
  name = "vpc_sg_public"
  description = "Allow incoming HTTP connections & SSH access"
  vpc_id = aws_vpc.vpc.id
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks =  ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  tags = {
    "Name" = "SG Public"
  }
}

#NAT
resource "aws_eip" "ngw" {
    vpc = true
}
resource "aws_nat_gateway" "public" {
    depends_on = [aws_internet_gateway.ig]

    allocation_id = aws_eip.ngw.id
    subnet_id     = aws_subnet.public_subnet[0].id

    tags = {
      Name = "Public NAT"
  }
}
resource "aws_route_table" "private_rt" {
    vpc_id = aws_vpc.vpc.id
    
    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_nat_gateway.public.id
    }
    tags = {
      "Name" = "Private RT"
    }
}
resource "aws_route_table_association" "public_private_rt" {
    for_each = { for k, v in aws_subnet.private_subnet : k => v }
    subnet_id = each.value.id
    route_table_id = aws_route_table.private_rt.id
}

# Create EC2

resource "aws_instance" "web-server" {
  
  count = 5
  key_name                = "keyall"
  ami                     = "ami-0dfcb1ef8550277af"
  instance_type           = "t2.micro"
  vpc_security_group_ids  = ["${aws_security_group.sg_public.id}"]
  subnet_id               = element(aws_subnet.public_subnet.*.id, count.index)
  associate_public_ip_address = true
  source_dest_check = false
  user_data = file("userdata.sh")
  tags = {
    Name = "web-srv-${var.public_subnet[count.index]}"
  }
}

resource "aws_instance" "app-server" {
  
  count = 5
  key_name                = "keyall"
  ami                     = "ami-0dfcb1ef8550277af"
  instance_type           = "t2.micro"
  vpc_security_group_ids  = ["${aws_security_group.sg_public.id}"]
  subnet_id               = element(aws_subnet.private_subnet.*.id, count.index)
  associate_public_ip_address = true
  user_data = file("userdata.sh")
  source_dest_check = false
  tags = {
    Name = "app-srv-${var.private_subnet[count.index]}"
  }
}
