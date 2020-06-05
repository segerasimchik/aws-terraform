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

resource "aws_default_route_table" "my" {
    default_route_table_id = aws_vpc.my_vpc.default_route_table_id
    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.my_gw.id
    }
    tags = {
      Name = "My Route table"
    }
}

resource "aws_main_route_table_association" "tab" {
    vpc_id = aws_vpc.my_vpc.id
    route_table_id = aws_default_route_table.my.id
}

##### First subnet #####

resource "aws_subnet" "my_sub" {
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = "10.1.10.0/24"
    map_public_ip_on_launch = true
    availability_zone = "eu-west-3a"
    tags = {
      Name = "From Terraform"
    }
}

##### Second subnet ######

resource "aws_subnet" "my_sec_sub" {
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = "10.1.20.0/24"
    availability_zone = "eu-west-3b"
    tags = {
      Name = "From Terraform With Love"
    }
}

########## Security Groups ##########

##### SG allow ssh #####
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

##### SG allow http #####
resource "aws_security_group" "http" {
    name = "HTTP/HTTPS"
    vpc_id = aws_vpc.my_vpc.id

    ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
      from_port = 443
      to_port = 443
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

########## EC2_instances ##########

##### Instance with publicIP #####

resource "aws_instance" "host_1" {
    ami = "ami-08c757228751c5335"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.my_sub.id
    private_ip = "10.1.10.100"
    security_groups = ["${aws_security_group.ssh.id}",
      "${aws_security_group.http.id}"]
    key_name = var.key_name
    tags = {
      Name = "Host_IFaced"
    }
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = file("~/.ssh/regular.pem")
      host = self.public_ip
    }
    provisioner "remote-exec" {
      inline = [
        "sudo apt update",
        "sudo apt install -y nginx",
      ]
    }
}

##### Instance with just privateIP #####

resource "aws_instance" "host_2" {
    ami = "ami-08c757228751c5335"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.my_sec_sub.id
    private_ip = "10.1.20.200"
    security_groups = ["${aws_security_group.ssh.id}"]
    key_name = var.key_name
    tags = {
      Name = "Host_Internal"
    }
  }
