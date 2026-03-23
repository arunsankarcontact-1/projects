##########################################################
# Provider configuration
##########################################################
provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

##########################################################
# Get the latest Ubuntu AMI
##########################################################
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

##########################################################
# Security group for Jenkins
##########################################################
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Allow SSH and Jenkins"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins access"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-sg"
  }
}

##########################################################
# Get default VPC and subnet
##########################################################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "default" {
  default_for_az = true
  availability_zone = data.aws_availability_zones.available.names[0]
}

data "aws_availability_zones" "available" {}

##########################################################
# EC2 Instance for Jenkins
##########################################################
resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = data.aws_subnet.default.id
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    set -eux
    sudo apt update
    sudo apt install -y fontconfig openjdk-17-jre gnupg curl ca-certificates
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key -o /tmp/jenkins.key
    gpg --dearmor /tmp/jenkins.key
    mv /tmp/jenkins.key.gpg /usr/share/keyrings/jenkins.gpg
    chmod 644 /usr/share/keyrings/jenkins.gpg
    echo "deb [signed-by=/usr/share/keyrings/jenkins.gpg] https://pkg.jenkins.io/debian-stable binary/"  > /etc/apt/sources.list.d/jenkins.list
    sudo apt update
    sudo apt install -y jenkins
    sudo systemctl enable jenkins
    sudo systemctl start jenkins
  EOF

  tags = {
    Name = "jenkins-server"
  }
}

##########################################################
# Output public IP
##########################################################
output "jenkins_public_ip" {
  description = "Public IP of Jenkins server"
  value       = aws_instance.jenkins.public_ip
}

output "jenkins_url" {
  description = "Access Jenkins here"
  value       = "http://${aws_instance.jenkins.public_ip}:8080"
}
