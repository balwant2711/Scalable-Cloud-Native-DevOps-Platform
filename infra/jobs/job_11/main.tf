terraform {
  required_version = ">= 1.0.0"

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

# Latest Amazon Linux 2023 AMI (x86_64)
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  key_name                    = var.key_pair_name
  associate_public_ip_address = true

  subnet_id = "subnet-0696e3f358fdf50eb"

  tags = {
    Name = var.instance_name
  }

  user_data = <<-EOF
#!/bin/bash

yum update -y

# Install nginx + git
yum install -y nginx git

# Start nginx
systemctl enable nginx
systemctl start nginx

# Go to web root
cd /usr/share/nginx/html

# Remove default files
rm -rf *

# Clone your portfolio repo
git clone https://github.com/balwant2711/Devops-Portfolio .

# Restart nginx
systemctl restart nginx

# Wait for server to be ready
sleep 60

# 🔥 Replace with your EC2 IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
DOMAIN="$PUBLIC_IP.nip.io"

# 🔒 Install SSL
certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m test@example.com

# Auto renew
systemctl enable certbot-renew.timer
EOF
}
