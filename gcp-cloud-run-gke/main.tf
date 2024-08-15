provider "google" {
  project = "ctp-prj-1"
  region  = "us-central1" # Adjust as needed
}

# Existing configuration...

resource "kubernetes_deployment" "gke_app" {
  metadata {
    name      = "gke-app"
    namespace = "default"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "gke-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "gke-app"
        }
      }

      spec {
        container {
          image = "gcr.io/ctp-prj-1/gke-app:latest"
          name  = "gke-app"

          # The 'ports' block is not used directly here in the Terraform resource for GKE. 
          # Ensure you use the correct syntax inside the Kubernetes manifest.

          # This is a placeholder to show where ports typically go in Kubernetes YAML:
          # ports {
          #   container_port = 3000
          # }
        }
      }
    }
  }
}

resource "kubernetes_service" "gke_app_service" {
  metadata {
    name      = "gke-app"
    namespace = "default"
  }

  spec {
    selector = {
      app = "gke-app"
    }

    port {
      port        = 80
      target_port = 3000
    }

    type = "ClusterIP"
  }
}

# Update Cloud Run service to include environment variable for GKE service URL
resource "google_cloud_run_service" "cloud_run_service" {
  name     = "hello-world"
  location = "us-central1"

  template {
    spec {
      containers {
        image = "gcr.io/ctp-prj-1/cloud-run-app:latest"

        env {
          name  = "GKE_SERVICE_URL"
          value = "http://gke-app.default.svc.cluster.local"
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}


# Grant Cloud Run Invoker role to allow the service to be publicly accessible
resource "google_cloud_run_service_iam_member" "invoker" {
  service = google_cloud_run_service.cloud_run_service.name
  location = google_cloud_run_service.cloud_run_service.location
  role    = "roles/run.invoker"
  member  = "allUsers"
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
