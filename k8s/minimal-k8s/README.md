Overview
--------------

This project provisions a minimal single-node Kubernetes cluster on AWS using Terraform and initializes it using kubeadm.

It is designed as a lightweight, production-like lab environment to understand Kubernetes fundamentals, networking, and deployment workflows without using managed services.

kube api server can be accessed from the localhost using NodeIP

scp -i key.pem ubuntu@{public_IP}:/home/ubuntu/kubeconfig ~/.

Architecture: 
--------------

Cloud Provider: AWS

Instance: Single EC2 (Ubuntu 22.04)

Container Runtime: containerd

Kubernetes Bootstrap: kubeadm

CNI Plugin: Flannel

Features
--------------

Automated EC2 provisioning using Terraform

Secure key pair generation

Full Kubernetes setup via userdata.sh

containerd configured with CRI support

Automatic cluster initialization (kubeadm init)

Flannel network plugin installation

Control-plane node untainted (usable for workloads)

Project Structure
--------------
.
├── main.tf          # AMI data source
├── provider.tf      # AWS provider configuration
├── ec2.tf           # EC2 configuration
├── keypair.tf       # SSH key generation
├── security.tf      # Security group configuration
├── variables.tf     # Input variables
├── output.tf        # Outputs (e.g., public IP)
├── userdata.sh      # Kubernetes bootstrap script

Commands
--------------

 kubectl --insecure-skip-tls-verify=true get po -A
 kubectl --insecure-skip-tls-verify=true get no -A
 kubectl --insecure-skip-tls-verify=true get svc -A

