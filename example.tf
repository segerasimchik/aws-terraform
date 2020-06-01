provider "aws" {
  profile = var.profile
  region = var.region
}

########## Network description ##########

resource "aws_vpc" "my_vpc" {
    cidr_block = "10.1.0.0/16"
    tags = {
      Name = "MyVPC"
    }
}

resource "aws_internet_gateway" "my_gw" {
    vpc_id = aws_vpc.my_vpc.id
    tags = {
      Name = "MyInternetGateway"
    }
}
resource "aws_route_table" "my" {
    vpc_id = aws_vpc.my_vpc.id
    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.my_gw.id
    }
}

resource "aws_main_route_table_association" "tab" {
    vpc_id = aws_vpc.my_vpc.id
    route_table_id = aws_route_table.my.id
}

resource "aws_subnet" "my_vpc" {
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = "10.1.10.0/24"
    map_public_ip_on_launch = true
    tags = {
      Name = "From Terraform"
    }
}

resource "aws_security_group" "ssh" {
    name = "Just SSH"
    vpc_id = aws_vpc.my_vpc.id

    ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
}

########## End of network description ##########

########## EC2_instance ##########

resource "aws_instance" "host_1" {
    ami = "ami-08c757228751c5335"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.my_vpc.id
    security_groups = ["${aws_security_group.ssh.id}"]
    key_name = var.key_name
    tags = {
      Name = "host_1"
    }
  }
