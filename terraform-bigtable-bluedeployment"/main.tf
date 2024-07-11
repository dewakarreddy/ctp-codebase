provider "google" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}

# Bigtable Instance
resource "google_bigtable_instance" "bigtable_instance" {
  name                = var.instance_name
  project             = var.project_id
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

# External data source to get access token
data "external" "access_token" {
  program = ["bash", "${path.module}/get_access_token.sh"]
}

# Bigtable Backup creation using null_resource and local-exec with gcloud
resource "null_resource" "create_backup" {
  provisioner "local-exec" {
    command = <<-EOT
      expiration_date=$(date -d '+89 days' -u +"%Y-%m-%dT%H:%M:%SZ")
      gcloud bigtable backups create ${var.backup_id} \
        --instance=${google_bigtable_instance.bigtable_instance.name} \
        --cluster=${var.cluster_id} \
        --table=${google_bigtable_table.bigtable_table.name} \
        --expiration-date=$expiration_date
    EOT
  }
  triggers = {
    always_run = "${timestamp()}"
  }
  depends_on = [google_bigtable_table.bigtable_table]
}

# Delete Bigtable backups using null_resource and local-exec with gcloud
resource "null_resource" "delete_backups" {
  provisioner "local-exec" {
    command = <<-EOT
      backups=$(gcloud bigtable backups list --instance=${google_bigtable_instance.bigtable_instance.name} --cluster=${var.cluster_id} --format="value(name)")
      for backup in $backups; do
        gcloud bigtable backups delete $backup --instance=${google_bigtable_instance.bigtable_instance.name} --cluster=${var.cluster_id} --quiet
      done
    EOT
  }
  triggers = {
    always_run = "${timestamp()}"
  }
  depends_on = [null_resource.create_backup]
}

# Helper to run curl commands with retries
resource "null_resource" "run_curl_commands" {
  count = length(local.curl_commands)

  provisioner "local-exec" {
    command = <<-EOT
      for i in {1..5}; do
        ${element(local.curl_commands, count.index)} && break || sleep 10;
      done
    EOT
  }

  triggers = {
    command = element(local.curl_commands, count.index)
  }
  depends_on = [google_bigtable_instance.bigtable_instance]
}

locals {
  curl_commands = [
    # Operations API
    "curl -X GET -H 'Authorization: Bearer ${data.external.access_token.result.token}' 'https://bigtable.googleapis.com/v2/${var.resource_name}'",
    "curl -X GET -H 'Authorization: Bearer ${data.external.access_token.result.token}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/operations'",
    "curl -x GET -H 'Authorization: Bearer ${data.external.access_token.result.token}' 'https://bigtable.googleapis.com/v2/{parent=projects/ctp-prj-1/instances/your-instance-name}/clusters'",
   
   # Instance API
    "curl -X POST -H 'Authorization: Bearer ${data.external.access_token.result.token}' -H 'Content-Type: application/json' -d '{\"instanceId\": \"${var.instance_name}\", \"clusters\": [{\"clusterId\": \"${var.cluster_id}\", \"zone\": \"${var.zone}\", \"serveNodes\": ${var.num_nodes}, \"defaultStorageType\": \"${var.storage_type}\"}]}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/instances'",
    "curl -X DELETE -H 'Authorization: Bearer ${data.external.access_token.result.token}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/instances/${var.instance_name}'",
    "curl -X GET -H 'Authorization: Bearer ${data.external.access_token.result.token}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/instances/${var.instance_name}'",
    "curl -X GET -H 'Authorization: Bearer ${data.external.access_token.result.token}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/instances'",
    "curl -X PATCH -H 'Authorization: Bearer ${data.external.access_token.result.token}' -H 'Content-Type: application/json' -d '{\"instance\": {\"displayName\": \"Updated Display Name\"}}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/instances/${var.instance_name}'",
    "curl -X POST -H 'Authorization: Bearer ${data.external.access_token.result.token}' -H 'Content-Type: application/json' -d '{\"policy\": {\"bindings\": [{\"role\": \"${var.iam_role}\", \"members\": ${jsonencode(var.iam_members)}]}}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/instances/${var.instance_name}:setIamPolicy'",
    "curl -X POST -H 'Authorization: Bearer ${data.external.access_token.result.token}' -H 'Content-Type: application/json' -d '{\"permissions\": ${jsonencode(var.permissions)}}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/instances/${var.instance_name}:testIamPermissions'",

        # App Profile API
    "curl -X POST -H 'Authorization: Bearer ${data.external.access_token.result.token}' -H 'Content-Type: application/json' -d '{\"appProfileId\": \"${var.app_profile_id}\", \"description\": \"App profile description\", \"singleClusterRouting\": {\"clusterId\": \"${google_bigtable_instance.bigtable_instance.cluster[0].cluster_id}\"}}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/instances/${var.instance_name}/appProfiles'",
    "curl -X DELETE -H 'Authorization: Bearer ${data.external.access_token.result.token}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/instances/${var.instance_name}/appProfiles/${var.app_profile_id}'",
    "curl -X GET -H 'Authorization: Bearer ${data.external.access_token.result.token}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/instances/${var.instance_name}/appProfiles/${var.app_profile_id}'",
    "curl -X GET -H 'Authorization: Bearer ${data.external.access_token.result.token}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/instances/${var.instance_name}/appProfiles'",
    "curl -X PATCH -H 'Authorization: Bearer ${data.external.access_token.result.token}' -H 'Content-Type: application/json' -d '{\"appProfile\": {\"description\": \"Updated app profile description\"}}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/instances/${var.instance_name}/appProfiles/${var.app_profile_id}'",
    # Cluster API
    "curl -X POST -H 'Authorization: Bearer ${data.external.access_token.result.token}' -H 'Content-Type: application/json' -d '{\"clusterId\": \"${var.cluster_id}\", \"zone\": \"${var.zone}\", \"serveNodes\": ${var.num_nodes}, \"defaultStorageType\": \"${var.storage_type}\"}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/instances/${var.instance_name}/clusters'",
    "curl -X DELETE -H 'Authorization: Bearer ${data.external.access_token.result.token}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/instances/${var.instance_name}/clusters/${var.cluster_id}'",
    "curl -X GET -H 'Authorization: Bearer ${data.external.access_token.result.token}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/instances/${var.instance_name}/clusters/${var.cluster_id}'",
    "curl -X GET -H 'Authorization: Bearer ${data.external.access_token.result.token}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/instances/${var.instance_name}/clusters'",
    "curl -X PATCH -H 'Authorization: Bearer ${data.external.access_token.result.token}' -H 'Content-Type: application/json' -d '{\"cluster\": {\"serveNodes\": ${var.num_nodes}}}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/instances/${var.instance_name}/clusters/${var.cluster_id}'",
    "curl -X PUT -H 'Authorization: Bearer ${data.external.access_token.result.token}' -H 'Content-Type: application/json' -d '{\"cluster\": {\"serveNodes\": ${var.num_nodes}, \"defaultStorageType\": \"${var.storage_type}\"}}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/instances/${var.instance_name}/clusters/${var.cluster_id}'",
    # Backup API
    "curl -X POST -H 'Authorization: Bearer ${data.external.access_token.result.token}' -H 'Content-Type: application/json' -d '{\"backupId\": \"${var.backup_id}\", \"expireTime\": \"${var.expire_time}\", \"sourceTable\": \"projects/${var.project_id}/instances/${var.instance_name}/tables/${google_bigtable_table.bigtable_table.name}\"}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/instances/${var.instance_name}/clusters/${var.cluster_id}/backups'",
    "curl -X POST -H 'Authorization: Bearer ${data.external.access_token.result.token}' -H 'Content-Type: application/json' -d '{\"sourceBackup\": \"projects/${var.project_id}/instances/${var.instance_name}/clusters/${var.cluster_id}/backups/${var.backup_id}\", \"expireTime\": \"${var.expire_time}\"}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/instances/${var.instance_name}/clusters/${var.cluster_id}/backups/${var.backup_id}:copy'",
    "curl -X DELETE -H 'Authorization: Bearer ${data.external.access_token.result.token}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/instances/${var.instance_name}/clusters/${var.cluster_id}/backups/${var.backup_id}'",
    "curl -X GET -H 'Authorization: Bearer ${data.external.access_token.result.token}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/instances/${var.instance_name}/clusters/${var.cluster_id}/backups/${var.backup_id}'",
    "curl -X GET -H 'Authorization: Bearer ${data.external.access_token.result.token}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/instances/${var.instance_name}/clusters/${var.cluster_id}/backups'",
    "curl -X PATCH -H 'Authorization: Bearer ${data.external.access_token.result.token}' -H 'Content-Type: application/json' -d '{\"backup\": {\"expireTime\": \"${var.expire_time}\"}}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/instances/${var.instance_name}/clusters/${var.cluster_id}/backups/${var.backup_id}'",
    "curl -X POST -H 'Authorization: Bearer ${data.external.access_token.result.token}' -H 'Content-Type: application/json' -d '{\"policy\": {\"bindings\": [{\"role\": \"${var.iam_role}\", \"members\": ${jsonencode(var.iam_members)}]}}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/instances/${var.instance_name}/clusters/${var.cluster_id}/backups/${var.backup_id}:setIamPolicy'",
    "curl -X POST -H 'Authorization: Bearer ${data.external.access_token.result.token}' -H 'Content-Type: application/json' -d '{\"permissions\": ${jsonencode(var.permissions)}}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/instances/${var.instance_name}/clusters/${var.cluster_id}/backups/${var.backup_id}:testIamPermissions'",
    # Hot Tablets API
    "curl -X GET -H 'Authorization: Bearer ${data.external.access_token.result.token}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/instances/${var.instance_name}/clusters/${var.cluster_id}/hotTablets'",
    # Table API
    "curl -X POST -H 'Authorization: Bearer ${data.external.access_token.result.token}' -H 'Content-Type: application/json' -d '{\"tableId\": \"${var.table_name}\", \"table\": {\"columnFamilies\": {\"cf1\": {}}}}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/instances/${var.instance_name}/tables'",
    "curl -X DELETE -H 'Authorization: Bearer ${data.external.access_token.result.token}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/instances/${var.instance_name}/tables/${var.table_name}'",
    "curl -X GET -H 'Authorization: Bearer ${data.external.access_token.result.token}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/instances/${var.instance_name}/tables/${var.table_name}'",
    "curl -X GET -H 'Authorization: Bearer ${data.external.access_token.result.token}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/instances/${var.instance_name}/tables'",
    "curl -X POST -H 'Authorization: Bearer ${data.external.access_token.result.token}' -H 'Content-Type: application/json' -d '{\"name\": \"${var.table_name}\", \"dropRowRange\": {\"rowKeyPrefix\": \"prefix-to-drop\"}}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/instances/${var.instance_name}/tables/${var.table_name}:dropRowRange'",
    "curl -X POST -H 'Authorization: Bearer ${data.external.access_token.result.token}' -H 'Content-Type: application/json' -d '{\"consistencyToken\": \"token\"}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/instances/${var.instance_name}/tables/${var.table_name}:checkConsistency'",
    "curl -X POST -H 'Authorization: Bearer ${data.external.access_token.result.token}' -H 'Content-Type: application/json' -d '{\"modifications\": [{\"id\": \"cf1\", \"create\": {\"gcRule\": {\"maxNumVersions\": 1}}}]}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/instances/${var.instance_name}/tables/${var.table_name}:modifyColumnFamilies'",
    "curl -X PATCH -H 'Authorization: Bearer ${data.external.access_token.result.token}' -H 'Content-Type: application/json' -d '{\"table\": {\"name\": \"${var.table_name}\"}}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/instances/${var.instance_name}/tables/${var.table_name}'",
    "curl -X POST -H 'Authorization: Bearer ${data.external.access_token.result.token}' -H 'Content-Type: application/json' -d '{\"backup\": \"projects/${var.project_id}/instances/${var.instance_name}/clusters/${var.cluster_id}/backups/${var.backup_id}\"}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/instances/${var.instance_name}/tables:restore'",
    "curl -X POST -H 'Authorization: Bearer ${data.external.access_token.result.token}' -H 'Content-Type: application/json' -d '{\"policy\": {\"bindings\": [{\"role\": \"${var.iam_role}\", \"members\": ${jsonencode(var.iam_members)}]}}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/instances/${var.instance_name}/tables/${var.table_name}:setIamPolicy'",
    "curl -X POST -H 'Authorization: Bearer ${data.external.access_token.result.token}' -H 'Content-Type: application/json' -d '{\"permissions\": ${jsonencode(var.permissions)}}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/instances/${var.instance_name}/tables/${var.table_name}:testIamPermissions'",
    "curl -X POST -H 'Authorization: Bearer ${data.external.access_token.result.token}' -H 'Content-Type: application/json' -d '{\"name\": \"${var.table_name}\"}' 'https://bigtable.googleapis.com/v2/projects/${var.project_id}/instances/${var.instance_name}/tables/${var.table_name}:undelete'"
  ]
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

output "backup_id" {
  value = var.backup_id
}
