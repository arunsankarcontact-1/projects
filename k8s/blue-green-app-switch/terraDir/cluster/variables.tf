variable "region" {
  default = "us-west-2"
}

variable "key_name" {
  default = "Proj1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  default = "10.0.1.0/24"
}

variable "instance_type" {
  default = "t3.small"
}
