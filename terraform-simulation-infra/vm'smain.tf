resource "google_compute_instance" "bastion_1" {
  name         = "bastion-1"
  machine_type = "f1-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.self_link
    subnetwork = google_compute_subnetwork.subnet.self_link

    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    ssh-keys = var.bastion_ssh_keys
  }
}

resource "google_compute_instance" "bastion_2" {
  name         = "bastion-2"
  machine_type = "f1-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.self_link
    subnetwork = google_compute_subnetwork.subnet.self_link

    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    ssh-keys = var.bastion_ssh_keys
  }
}
