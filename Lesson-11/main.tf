#----------------------------------------------------------
# Provision Highly Availabe Web in any Region Default VPC
# Create:
#    - Security Group for Web Server
#    - Launch Configuration with Auto AMI Lookup
#    - Auto Scaling Group using 2 Availability Zones
#    - Classic Load Balancer in 2 Availability Zones
#
# Made by Denis Astahov 11-June-2019
#-----------------------------------------------------------

provide "aws" {
  region = "eu-central-1"
}

data "aws_availability_zones" "available" {}

data "aws_ami" "latest_linux" {
  owners      = ["137112412989"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-*-x86_64-gp2"]
  }
}

#-----------------------------------------------------------

resource "aws_security_group" "my_webserver" {
  name = "My Security Group"

  dynamic "ingress" {
    for_each = ["80", "443", "22"]
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
    Name = "My SecurityGroup"
  }
}

resource "aws_launch_configuration" "web" {
  name                   = "web_server"
  image_id               = data.aws_ami.latest_linux.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.my_webserver.id]
  user_data              = file("user_data.sh")

  lifecycle {
    create_before_destroy = true
  }
}

#-----------------------------------------------------------

resource "aws_autoscaling_group" "web" {
  name                 = "web_server_asg"
  launch_configuration = aws_launch_configuration.web.name
  min_size             = 2
  max_size             = 2
  min_elb_capacity     = 2
  vpc_zone_identifier  = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  load_balancers       = [aws_elb.web.name]
  health_check_type    = "ELB"

  dynamic "tag" {
    for_each = {
      Name  = "web_server_in_asg"
      Owner = "Opti"
    }
  }
  content {
    key                 = tag.key
    value               = tag.value
    propagate_at_launch = true
  }
  lifecycle {
    create_before_destroy = true
  }

}

#----------------------------------------------------------

resource "aws_elb" "web" {
  name               = "web_server_elb"
  availability_zones = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  security_groups    = [aws_security_group.my_webserver.id]
  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = "80"
    instance_protocol = "http"
  }
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 10
  }
  tags = {
    Name = "web_server_ha_elb"
  }
}

resource "aws_default_subnet" "default_az1" {
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_default_subnet" "default_az2" {
  availability_zone = data.aws_availability_zones.available.names[1]
}

#-----------------------------------------------------------

output "web_elb_url" {
  value = aws_elb.web.dns_name
}
