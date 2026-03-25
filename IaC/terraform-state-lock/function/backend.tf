terraform {
  backend "gcs" {
    bucket  = "tfstate-maintainer"
    prefix  = "cloud-function-state"
  }
}
