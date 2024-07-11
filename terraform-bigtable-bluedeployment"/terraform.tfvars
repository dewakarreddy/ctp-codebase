# Bigtable instance configuration
bigtable_instance_name = "bigtable-instance"
bigtable_instance_type = "PRODUCTION"
bigtable_cluster_id    = "bigtable-cluster"
bigtable_num_nodes     = 1

# Bigtable table configuration
bigtable_table_name    = "bigtable-table"
bigtable_column_family = "cf1"

project_id    = "ctp-prj-1"
region        = "us-central1"
zone          = "us-central1-a"
instance_name = "your-instance-name"
app_profile_id = "ctp-prj-profile"
cluster_id    = "ctp-prj-cluster"
num_nodes     = 3
storage_type  = "SSD"  # or "HDD"
new_num_nodes = 5
backup_id     = "ctp-prj-backup"
source_backup = "projects/your-project-id/instances/your-instance-name/clusters/your-cluster-id/backups/source-backup-id"
expire_time   = "2024-12-31T23:59:59Z"  # Expire time in RFC3339 UTC "Zulu" format
iam_role      = "roles/bigtable.user"
iam_members   = ["dewakarrerddy@google.com"]
permissions   = ["bigtable.backups.create", "bigtable.backups.restore"]

# Example for getting information about an instance
resource_name = "projects/your-project-id/instances/your-instance-id"

# Example for getting information about a backup
# resource_name = "projects/your-project-id/instances/your-instance-id/clusters/your-cluster-id/backups/your-backup-id"
