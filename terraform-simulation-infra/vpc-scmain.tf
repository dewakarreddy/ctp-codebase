resource "google_access_context_manager_access_policy" "access_policy" {
  parent = "organizations/${var.organization_id}"
  title  = var.policy_title
}

resource "google_access_context_manager_service_perimeter" "perimeter" {
  name        = "my-perimeter"
  parent      = google_access_context_manager_access_policy.access_policy.name
  title       = var.perimeter_title
  perimeter_type = "PERIMETER_TYPE_REGULAR"

  status {
    resources = [
      "projects/${var.project_id}",
    ]

    restricted_services = [
      "bigtable.googleapis.com",
      "sqladmin.googleapis.com",
      "run.googleapis.com",
      "container.googleapis.com",
    ]

    vpc_accessible_services {
      enable_restriction = true
      allowed_services   = ["bigtable.googleapis.com", "sqladmin.googleapis.com"]
    }
  }
}
