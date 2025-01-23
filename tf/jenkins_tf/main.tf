terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

variable "key_name" {
  description = "AWS key pair name"
  type        = string
  default     = "INT_AWS_KEY"
}

variable "security_group_id" {
  description = "Security Group ID"
  type        = string
  default     = "sg-02b3d29bdcd49a0cc"
}

variable "subnet_id" {
  description = "Subnet ID"
  type        = string
  default     = "subnet-06d26c27601fa5b42"
}

resource "aws_instance" "backend-jenkins" {
  ami           = "ami-05d38da78ce859165"
  instance_type = "t2.micro"
  count        = 1
  key_name      = var.key_name
  subnet_id     = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
    tags = {
    Purpose     = "jenkins"  
    Name        = "tpp_jenkins"
    Owner       = "Denis"
  }
}


resource "aws_instance" "backend-docker" {
  ami           = "ami-05d38da78ce859165"
  instance_type = "t2.micro"
  count        = 1
  key_name      = var.key_name
  subnet_id     = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  tags = {
    Purpose     = "docker_agent"
    Name        = "tpp_docker_agent"
    Owner       = "Denis"
  }
}


resource "aws_instance" "backend-ansible" {
  ami           = "ami-05d38da78ce859165"
  instance_type = "t2.micro"
  count        = 1
  key_name      = var.key_name
  subnet_id     = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  tags = {
    Purpose     = "ansible_agent"
    Name        = "tpp_ansible_agent"
    Owner       = "Denis"
  }
}