#--------------------------------
# My Terraform
#
# Variables
#
# Made by Opti93
#--------------------------------

provider "aws" {
  region = "eu-central-1"
}

data "aws_ami" "latest_amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_eip" "my_static_ip" {
  instance = aws_instance.my_server.id
  tags = {
    Name    = "Server IP"
    Owner   = "Opti"
    Project = "Phoenix"
  }
}

resource "aws_instance" "my_server" {
  ami                    = data.aws_ami.latest_amazon_linux.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.my_server.id]

  tags = {
    Name    = "Server Build by Terraform"
    Owner   = "Opti"
    Project = "Phoenix"
  }
}

resource "aws_security_group" "my_server" {
  name = "My security group"

  dynamic "ingress" {
    for_each = ["80", "443"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name    = "Server SecurityGroup"
    Owner   = "Opti"
    Project = "Phoenix"
  }
}
