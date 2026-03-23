provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region

  default_tags {
    tags = {
      Project     = "k8s-minimal"
      Env = "DEV"
    }
  }
}
