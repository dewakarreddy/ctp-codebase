provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_storage_bucket" "artifacts" {
  name          = "${var.project_id}-artifacts"
  location      = var.region
  force_destroy = true
}

resource "google_storage_bucket_iam_binding" "artifacts_binding" {
  bucket = google_storage_bucket.artifacts.name

  role = "roles/storage.admin"

  members = [
    "user:dewakarreddy@google.com"
  ]
}

output "registry_url" {
  value = "gcr.io/${var.project_id}"
}
