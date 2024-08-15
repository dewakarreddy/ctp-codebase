resource "google_compute_firewall" "allow_ingress_from_cloud_run" {
  name    = "allow-ingress-from-cloud-run"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ingress-controller"]
}

resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  source_ranges = [var.subnet_cidr]
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_bastion_to_sql" {
  name    = "allow-bastion-to-sql"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["5432"] // Port for PostgreSQL
  }

  source_ranges = [
    google_compute_instance.bastion_1.network_interface.0.network_ip,
    google_compute_instance.bastion_2.network_interface.0.network_ip
  ]
}

resource "google_compute_firewall" "allow_bastion_to_bigtable" {
  name    = "allow-bastion-to-bigtable"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = [
    google_compute_instance.bastion_1.network_interface.0.network_ip,
    google_compute_instance.bastion_2.network_interface.0.network_ip
  ]
}
