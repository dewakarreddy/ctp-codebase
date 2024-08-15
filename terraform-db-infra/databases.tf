provider "google" {
  project = "ctp-prj-1"
  region  = "us-central1"
}

# Create Spanner Instance
resource "google_spanner_instance" "spanner_instance" {
  name         = "spanner-ctp-001"
  config       = "regional-us-central1"
  display_name = "Spanner Instance"
  num_nodes    = 1
}

# Create Spanner Database
resource "google_spanner_database" "spanner_database" {
  name     = "spanner-database"
  instance = google_spanner_instance.spanner_instance.name

  ddl = [
    "CREATE TABLE Singers (SingerId INT64 NOT NULL, FirstName STRING(1024), LastName STRING(1024)) PRIMARY KEY (SingerId)"
  ]
}

# Create Bigtable Instance
resource "google_bigtable_instance" "bigtable_instance" {
  name         = "bigtable-ctp-001"
  cluster {
    cluster_id   = "bigtable-cluster"
    zone         = "us-central1-a"
    num_nodes    = 3
    storage_type = "SSD"
  }
  instance_type = "PRODUCTION"
}

# Create Bigtable Table
# Create Bigtable Table
resource "google_bigtable_table" "bigtable_table" {
  instance_name = google_bigtable_instance.bigtable_instance.name
  name = "bigtable-table"
}

# IAM Binding for Spanner
resource "google_project_iam_binding" "spanner_iam_binding" {
  project = "ctp-prj-1"
  role    = "roles/spanner.databaseUser"

  members = [
    "serviceAccount:gke-spanner-bigtable@ctp-prj-1.iam.gserviceaccount.com"
  ]
}

# IAM Binding for Bigtable
resource "google_project_iam_binding" "bigtable_iam_binding" {
  project = "ctp-prj-1"
  role    = "roles/bigtable.user"

  members = [
    "serviceAccount:gke-spanner-bigtable@ctp-prj-1.iam.gserviceaccount.com"
  ]
}
