provider "google" {
  project = "ctp-prj-1"
  region  = "us-central1" # Adjust as needed
}

# Define a VPC network
resource "google_compute_network" "vpc_network" {
  name = "vpc-fin-ctp"
  auto_create_subnetworks = false
  
}

# Define a primary subnet with secondary ranges for GKE
resource "google_compute_subnetwork" "subnet" {
  name          = "subnet-fin-ctp"
  ip_cidr_range = "10.0.0.0/16"  # Primary CIDR range
  region        = "us-central1"
  network       = google_compute_network.vpc_network.id

  # Secondary ranges for GKE Pods and Services
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.1.0.0/16"
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.2.0.0/16"
  }
}

# Create a firewall rule to allow SSH access to GKE nodes
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["10.0.0.0/16"]
}

# Create a GKE cluster
resource "google_container_cluster" "gke_cluster" {
  name     = "gke-cluster"
  location = "us-central1"

  network    = google_compute_network.vpc_network.id
  subnetwork = google_compute_subnetwork.subnet.id

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  initial_node_count = 1

  node_config {
    machine_type = "e2-medium"
  }
}

# Allow GKE to communicate with Cloud Run by setting IAM policies
resource "google_project_iam_member" "gke_cloud_run_invoker" {
  project = "ctp-prj-1"
  role    = "roles/run.invoker"
  member  = "serviceAccount:service-99607936596@container-engine-robot.iam.gserviceaccount.com"
}

# Allow Cloud Run to communicate with GKE
resource "google_project_iam_member" "cloud_run_gke_invoker" {
  project = "ctp-prj-1"
  role    = "roles/container.developer"
  member  = "serviceAccount:service-99607936596@serverless-robot-prod.iam.gserviceaccount.com"
}
