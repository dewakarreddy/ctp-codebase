resource "google_container_cluster" "primary" {
  name               = var.gke_cluster_name
  location           = var.region
  network            = google_compute_network.vpc_network.name
  subnetwork         = google_compute_subnetwork.subnet.name
  remove_default_node_pool = true
  initial_node_count = 1

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-pods"
    services_secondary_range_name = "gke-services"
  }
}

resource "google_container_node_pool" "primary_nodes" {
  cluster    = google_container_cluster.primary.name
  location   = var.region
  count      = var.gke_node_count

  node_config {
    machine_type = var.gke_node_machine_type

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    labels = {
      name = format("gke-instance-%03d", count.index + 1)
    }

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  node_count = 1
}
