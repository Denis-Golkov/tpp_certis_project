terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS provider
provider "aws" {
  region = "us-west-2"
}

variable "key_name" {
  description = "AWS key pair name"
  type        = string
  default     = "INT_AWS_KEY"
}

# Define the first EC2 instance resource
resource "aws_instance" "tpp_app1" {
  ami             = "ami-00c257e12d6828491"
  instance_type   = "t2.micro"
  key_name        = var.key_name
  vpc_security_group_ids = ["sg-02b3d29bdcd49a0cc"]
    tags = {
    Purpose     = "tpp_prod"  
    Name        = "tpp_app1"
    Owner       = "Denis"
  }
}

# Define the second EC2 instance resource
resource "aws_instance" "tpp_app2" {
  ami             = "ami-00c257e12d6828491"
  instance_type   = "t2.micro"
  key_name        = var.key_name
  vpc_security_group_ids = ["sg-02b3d29bdcd49a0cc"]
    tags = {
    Purpose     = "tpp_prod"  
    Name        = "tpp_app2"
    Owner       = "Denis"
  }
}

# Data source to get the default VPC
data "aws_vpc" "default_vpc" {
  default = true
}

# Data source to get the subnet IDs of the default VPC
data "aws_subnet_ids" "default_subnet" {
  vpc_id = data.aws_vpc.default_vpc.id
}

# Define the Application Load Balancer
resource "aws_lb" "load_balancer" {
  name               = "tpp-app-lb"
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.default_subnet.ids
  security_groups    = ["sg-02b3d29bdcd49a0cc"]
}

# Define the HTTP listener for the ALB
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  # Default action to return a 404 response
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

# Define the target group for the EC2 instances
resource "aws_lb_target_group" "instances" {
  name     = "tpp-tg"
  port     = 8081
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default_vpc.id

  # Health check configuration
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2

  }

  stickiness {
    type            = "lb_cookie"
    enabled         = true
    cookie_duration = 86400  # Duration(86400 = 1 day)
  }
}

# Attach the first EC2 instance to the target group
resource "aws_lb_target_group_attachment" "tpp_app1" {
  target_group_arn = aws_lb_target_group.instances.arn
  target_id        = aws_instance.tpp_app1.id
  port             = 8081
}

# Attach the second EC2 instance to the target group
resource "aws_lb_target_group_attachment" "tpp_app2" {
  target_group_arn = aws_lb_target_group.instances.arn
  target_id        = aws_instance.tpp_app2.id
  port             = 8081
}

# Define the listener rule to forward traffic to the target group
resource "aws_lb_listener_rule" "instances" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.instances.arn
  }
}

# Output the public IP address of the first instance
output "instance_1_public_ip" {
  description = "The public IP address of instance 1"
  value       = aws_instance.tpp_app1.public_ip
}

# Output the public IP address of the second instance
output "instance_2_public_ip" {
  description = "The public IP address of instance 2"
  value       = aws_instance.tpp_app2.public_ip
}

# Output the DNS name of the load balancer
output "load_balancer_dns" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.load_balancer.dns_name
}