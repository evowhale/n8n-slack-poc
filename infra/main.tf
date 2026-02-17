terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# --- 최신 Ubuntu 22.04 AMI ---
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# --- 보안 그룹 ---
resource "aws_security_group" "n8n_poc" {
  name        = "n8n-slack-poc-sg"
  description = "n8n + Claude Code POC"

  # SSH - 내 IP만
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # n8n UI - 내 IP만
  ingress {
    description = "n8n UI"
    from_port   = 5678
    to_port     = 5678
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # HTTPS - Slack webhook용 (전체 허용)
  ingress {
    description = "HTTPS for Slack webhook"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 아웃바운드 전체 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "n8n-slack-poc"
  }
}

# --- EC2 인스턴스 ---
resource "aws_instance" "n8n_poc" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.n8n_poc.id]

  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp3"
  }

  user_data = file("${path.module}/user-data.sh")

  tags = {
    Name = "n8n-slack-poc"
  }
}

# --- Elastic IP ---
resource "aws_eip" "n8n_poc" {
  instance = aws_instance.n8n_poc.id
  domain   = "vpc"

  tags = {
    Name = "n8n-slack-poc"
  }
}
