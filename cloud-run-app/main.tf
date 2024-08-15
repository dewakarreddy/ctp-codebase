provider "google" {
  project = "ctp-prj-1"
  region  = "us-central1" # Adjust as needed
}

# Define an existing VPC network
data "google_compute_network" "vpc_network" {
  name = "vpc-fin-ctp"
}

# Define an existing subnet
data "google_compute_subnetwork" "subnet" {
  name    = "subnet-fin-ctp"
  region  = "us-central1" # Same region as your Cloud Run service
}

# Create a VPC connector
resource "google_vpc_access_connector" "vpc_connector" {
  name   = "cloud-run-vpc-connector"
  region = "us-central1"

  network       = data.google_compute_network.vpc_network.id
  ip_cidr_range = "10.8.0.0/28" # Adjust as needed
}

# Deploy a Cloud Run service
resource "google_cloud_run_service" "cloud_run_service" {
  name     = "hello-world"
  location = "us-central1"

  template {
    spec {
      containers {
        image = "gcr.io/ctp-prj-1/cloud-run-app:latest"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# Allow unauthenticated access to the Cloud Run service
resource "google_cloud_run_service_iam_member" "invoker" {
  service  = google_cloud_run_service.cloud_run_service.name
  location = google_cloud_run_service.cloud_run_service.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
