resource "google_organization_policy" "restrict_resource_locations" {
  org_id     = var.org_id
  constraint = "constraints/gcp.resourceLocations"

  list_policy {
    allow {
      values = ["in:us-locations"]
    }
  }
}


resource "google_organization_policy" "list_restricted_services" {
  org_id     = var.org_id
  constraint = "constraints/gcp.restrictServiceUsage"

  list_policy {
    deny {
      values = [
        "firebaserules.googleapis.com",
        "firebasestorage.googleapis.com",
        "firestore.googleapis.com",
        "firestorekeyvisualizer.googleapis.com",
        "aiplatform.googleapis.com"
      ]
    }
  }
}

output "restrict_resource_locations" {
  value = google_organization_policy.restrict_resource_locations
}

output "list_restricted_services" {
  value = google_organization_policy.list_restricted_services
}
