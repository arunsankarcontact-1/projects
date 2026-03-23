variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "kubetest"
}

variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "us-west-2"
}

variable "instance_type" {
  description = "EC2 instance type for Jenkins"
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "Name of the existing AWS key pair"
  type        = string
  default     = "ec2Jen"
}
