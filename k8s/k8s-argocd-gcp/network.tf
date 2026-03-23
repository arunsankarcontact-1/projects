resource "google_compute_network" "vpc" {
  name                    = "k8s-vpc"
  auto_create_subnetworks = true
}
