variable "aws_profile" {
  description = "AWS CLI profile"
  type        = string
  default     = "kubetest"
}
variable "key_name" {
  description = "EC2 Key Pair name"
  type        = string
  default     = "k8s-key"
}
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}
