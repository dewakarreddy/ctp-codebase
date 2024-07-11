# Define the GCP provider
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Bigtable Instance
resource "google_bigtable_instance" "bigtable_instance" {
  name               = var.instance_name
  project            = var.project_id
  deletion_protection = false

  cluster {
    cluster_id   = var.cluster_id
    zone         = var.zone
    num_nodes    = var.num_nodes
    storage_type = var.storage_type
  }
  instance_type = "PRODUCTION"
}

# Bigtable App Profile
resource "google_bigtable_app_profile" "bigtable_app_profile" {
  instance       = google_bigtable_instance.bigtable_instance.name
  app_profile_id = var.app_profile_id
  description    = "App profile description"
  single_cluster_routing {
    cluster_id = google_bigtable_instance.bigtable_instance.cluster[0].cluster_id
  }
  ignore_warnings = true
}

# Bigtable Table
resource "google_bigtable_table" "bigtable_table" {
  name          = var.table_name
  instance_name = google_bigtable_instance.bigtable_instance.name
  column_family {
    family = "cf1"
  }
}

# IAM Policy for Instance
resource "google_bigtable_instance_iam_binding" "instance_iam_binding" {
  instance = google_bigtable_instance.bigtable_instance.name
  role     = "roles/bigtable.user"

  members = [
    "user:dewakarreddy@google.com"
  ]
}

# IAM Policy for Table
resource "google_bigtable_table_iam_binding" "table_iam_binding" {
  instance = google_bigtable_instance.bigtable_instance.name
  table    = google_bigtable_table.bigtable_table.name
  role     = "roles/bigtable.user"

  members = [
    "user:dewakarreddy@google.com"
  ]
}

# Custom script to create an instance
resource "null_resource" "create_instance" {
  provisioner "local-exec" {
    command = <<EOT
      if ! gcloud bigtable instances describe ${var.instance_name} --project=${var.project_id} >/dev/null 2>&1; then
        gcloud bigtable instances create ${var.instance_name} \
          --display-name=${var.instance_name} \
          --cluster=${var.cluster_id} \
          --cluster-zone=${var.zone} \
          --cluster-num-nodes=${var.num_nodes} \
          --cluster-storage-type=${var.storage_type} \
          --project=${var.project_id} \
          --verbosity=debug
      else
        echo "Instance ${var.instance_name} already exists"
      fi
    EOT
  }
}

# Custom script to get instance information
resource "null_resource" "get_instance" {
  provisioner "local-exec" {
    command = <<EOT
      gcloud bigtable instances describe ${var.instance_name} \
        --project=${var.project_id}
    EOT
  }
  triggers = {
    instance_name = google_bigtable_instance.bigtable_instance.name
  }
  depends_on = [google_bigtable_instance.bigtable_instance]
}

# Custom script to get IAM policy
resource "null_resource" "get_iam_policy" {
  provisioner "local-exec" {
    command = <<EOT
      gcloud bigtable instances get-iam-policy ${var.instance_name} \
        --project=${var.project_id} \
        --flatten="bindings[].members" \
        --format="table(bindings.role)" \
        --filter="bindings.members:user:dewakarreddy@google.com"
    EOT
  }
  depends_on = [google_bigtable_instance.bigtable_instance]
}

# Custom script to list instances
resource "null_resource" "list_instances" {
  provisioner "local-exec" {
    command = <<EOT
      gcloud bigtable instances list --project=${var.project_id}
    EOT
  }
}

# Custom script to list tables in an instance
resource "null_resource" "list_tables" {
  provisioner "local-exec" {
    command = <<EOT
      gcloud bigtable tables list --instances=${var.instance_name} --project=${var.project_id}
    EOT
  }
}

# Custom script to partially update an instance
resource "null_resource" "partial_update_instance" {
  provisioner "local-exec" {
    command = <<EOT
      if gcloud bigtable instances describe ${var.instance_name} --project=${var.project_id} >/dev/null 2>&1; then
        gcloud bigtable instances update ${var.instance_name} \
          --display-name=${var.instance_name} \
          --project=${var.project_id}
      fi
    EOT
  }
  triggers = {
    instance_name = google_bigtable_instance.bigtable_instance.name
  }
  depends_on = [google_bigtable_instance.bigtable_instance]
}

# Custom script to set IAM policy
resource "null_resource" "set_iam_policy" {
  provisioner "local-exec" {
    command = <<EOT
      if [ -f policy.json ]; then
        gcloud bigtable instances set-iam-policy ${var.instance_name} policy.json \
        --project=${var.project_id}
      else
        echo "policy.json not found"
      fi
    EOT
  }
  depends_on = [google_bigtable_instance.bigtable_instance]
}

# Custom script to test IAM permissions
resource "null_resource" "test_iam_permissions" {
  provisioner "local-exec" {
    command = <<EOT
      gcloud projects get-iam-policy ${var.project_id} --flatten="bindings[].members" --format="table(bindings.role)" --filter="bindings.members:user:dewakarreddy@google.com"
    EOT
  }
  depends_on = [google_bigtable_instance.bigtable_instance]
}

# Custom script to update an instance
resource "null_resource" "update_instance" {
  provisioner "local-exec" {
    command = <<EOT
      if gcloud bigtable instances describe ${var.instance_name} --project=${var.project_id} >/dev/null 2>&1; then
        gcloud bigtable instances update ${var.instance_name} \
          --display-name=${var.instance_name} \
          --project=${var.project_id}
      fi
    EOT
  }
  triggers = {
    instance_name = google_bigtable_instance.bigtable_instance.name
  }
  depends_on = [google_bigtable_instance.bigtable_instance]
}


# Outputs
output "bigtable_instance_id" {
  value = google_bigtable_instance.bigtable_instance.id
}

output "bigtable_instance_name" {
  value = google_bigtable_instance.bigtable_instance.name
}

output "bigtable_table_id" {
  value = google_bigtable_table.bigtable_table.id
}

output "bigtable_app_profile_id" {
  value = google_bigtable_app_profile.bigtable_app_profile.id
}
