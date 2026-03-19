terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.5.0"
}

provider "aws" {
  profile = "kubetest"
  region  = "us-west-2"
}

# -----------------------------
# IAM Role for SSM
# -----------------------------
resource "aws_iam_role" "ssm_role" {
  name = "k8s-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# -----------------------------
# VPC & Networking
# -----------------------------
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "k8s_sg" {
  name        = "k8s-sg"
  description = "K8s SG"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow K8s API"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -----------------------------
# Ubuntu AMI
# -----------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# -----------------------------
# EC2 Instances
# -----------------------------
resource "aws_instance" "master" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.small"
  key_name                    = "Proj1"
  subnet_id                   = element(data.aws_subnets.default.ids, 0)
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name

  user_data = <<-EOF
              #!/bin/bash
              set -e
              apt-get update -y
              apt-get install -y apt-transport-https ca-certificates curl gpg
              curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/kubernetes.gpg
              echo "deb https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" > /etc/apt/sources.list.d/kubernetes.list
              apt-get update -y
              apt-get install -y kubelet kubeadm kubectl containerd awscli
              systemctl enable kubelet

              kubeadm init --pod-network-cidr=10.244.0.0/16 --kubernetes-version=1.29.0 | tee /root/kubeadm-init.out

              mkdir -p /root/.kube
              cp /etc/kubernetes/admin.conf /root/.kube/config

              # Install flannel CNI
              kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml --kubeconfig /etc/kubernetes/admin.conf

              # Extract join command and save to SSM
              JOIN_CMD=$(grep -A2 "kubeadm join" /root/kubeadm-init.out | tail -n3 | tr -d '\\')
              aws ssm put-parameter --name "k8s-join-cmd" --type "String" --overwrite --value "$JOIN_CMD" --region us-west-2
              EOF

  tags = {
    Name = "k8s-master"
  }
}

resource "aws_instance" "worker" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.small"
  key_name                    = "Proj1"
  subnet_id                   = element(data.aws_subnets.default.ids, 1)
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name

  user_data = <<-EOF
              #!/bin/bash
              set -e
              apt-get update -y
              apt-get install -y apt-transport-https ca-certificates curl gpg
              curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/kubernetes.gpg
              echo "deb https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" > /etc/apt/sources.list.d/kubernetes.list
              apt-get update -y
              apt-get install -y kubelet kubeadm kubectl containerd awscli
              systemctl enable kubelet

              # Fetch join command from SSM
              until aws ssm get-parameter --name "k8s-join-cmd" --query "Parameter.Value" --output text --region us-west-2 > /root/join.sh; do
                echo "Waiting for join command..."
                sleep 10
              done
              bash /root/join.sh
              EOF

  tags = {
    Name = "k8s-worker"
  }
}

# -----------------------------
# IAM Instance Profile
# -----------------------------
resource "aws_iam_instance_profile" "ssm_profile" {
  name = "k8s-ssm-profile"
  role = aws_iam_role.ssm_role.name
}

# -----------------------------
# Outputs
# -----------------------------
output "master_public_ip" {
  value = aws_instance.master.public_ip
}

output "worker_public_ip" {
  value = aws_instance.worker.public_ip
}

output "ssh_master" {
  value = "ssh -i Proj1.pem ubuntu@${aws_instance.master.public_ip}"
}

