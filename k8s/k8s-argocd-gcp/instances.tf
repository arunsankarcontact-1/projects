resource "google_compute_instance" "k8s_master" {
  name         = "k8s-master"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    network = google_compute_network.vpc.name
    access_config {}
  }

  metadata_startup_script = file("userdata-master.sh")

  tags = ["k8s-node"]
}

resource "google_compute_instance" "k8s_worker" {
  name         = "k8s-worker"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    network = google_compute_network.vpc.name
    access_config {}
  }

  metadata_startup_script = templatefile("userdata-worker.sh", {
    master_ip = google_compute_instance.k8s_master.network_interface[0].network_ip
  })

  depends_on = [google_compute_instance.k8s_master]

  tags = ["k8s-node"]
}
