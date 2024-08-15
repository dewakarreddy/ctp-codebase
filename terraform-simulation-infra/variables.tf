variable "project_id" {
  description = "The ID of the project where resources will be created."
  type        = string
  default     = "ctp-prj-1"
}

variable "region" {
  description = "The region where resources will be created."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The zone where resources will be created."
  type        = string
  default     = "us-central1-a"
}

variable "vpc_name" {
  description = "The name of the VPC network."
  type        = string
  default     = "vpc-fin-ctp-001"
}

variable "subnet_name" {
  description = "The name of the subnet."
  type        = string
  default     = "subnet-fin-ctp-001"
}

variable "subnet_cidr" {
  description = "The CIDR range for the subnet."
  type        = string
  default     = "10.0.0.0/24"
}

variable "spanner_instance_name" {
  description = "The name of the Cloud Spanner instance."
  type        = string
  default     = "ctp-fin-spanner-001"
}

variable "spanner_num_nodes" {
  description = "The number of nodes in the Cloud Spanner instance."
  type        = number
  default     = 1
}

variable "spanner_database_name" {
  description = "The name of the Cloud Spanner database."
  type        = string
  default     = "ctp-fin-db-001"
}

variable "cloud_run_image" {
  description = "The container image for the Cloud Run service."
  type        = string
  default     = "gcr.io"
}

variable "gke_cluster_name" {
  description = "The name of the GKE cluster."
  type        = string
  default     = "gke-fin-ctp-001"
}

variable "gke_node_count" {
  description = "The number of nodes in the GKE cluster."
  type        = number
  default     = 1
}

variable "gke_node_machine_type" {
  description = "The machine type for GKE nodes."
  type        = string
  default     = "n1-standard-1"
}

variable "cloud_sql_instance_name" {
  description = "The name of the Cloud SQL instance."
  type        = string
  default     = "sql-fin-ctp-001"
}

variable "cloud_sql_database_version" {
  description = "The version of the Cloud SQL database."
  type        = string
  default     = "POSTGRES_12"
}

variable "cloud_sql_tier" {
  description = "The tier for the Cloud SQL instance."
  type        = string
  default     = "db-f1-micro"
}

variable "bigtable_instance_name" {
  description = "The name of the Bigtable instance."
  type        = string
  default     = "big-fin-ctp-001"
}

variable "bigtable_cluster_id" {
  description = "The ID of the Bigtable cluster."
  type        = string
  default     = "bt-cluster-001"
}

variable "bigtable_num_nodes" {
  description = "The number of nodes in the Bigtable cluster."
  type        = number
  default     = 3
}

variable "bigtable_storage_type" {
  description = "The storage type for the Bigtable cluster."
  type        = string
  default     = "SSD"
}

variable "bastion_ssh_keys" {
  description = "The SSH keys for the bastion hosts."
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCeb3KMO6Byn6XjpHJQKRbPuFYKXPKTXcOJLtxntWHOxuLl6i6+SN9t/yYPaygWOWnPl9p5L/UchKkFSryiCKCXsQYfakmNJLtuvtpYd09MOu4sgtDYOxCD4vWblHuhBdXpqXx2a175F8gM7sCQYEfRaySjHUsdCEI5SaOJVYqCQSOq5CHc1fVB7SNYTlxFForsNyDObFgiJ7eDAWZa5o8bbkbxxN1WlI5F0YzS+Yiwf938dvAqK2yM9UExg42nEgd/yfZ8IvOzLNEvkESCDXuh0CsnTT6JMBoUHOb1Ts2zbHGFOkq+2G001Sy3FhVAgX3Y9ZfMlBDoNEqqSIVGz7P9 dewakarreddy@google.com"
}

variable "organization_id" {
  description = "The ID of the organization."
  type        = string
  default     = "486803701224"
}

variable "policy_title" {
  description = "The title of the access policy."
  type        = string
  default     = "ctp-vpc-sc"
}

variable "perimeter_title" {
  description = "The title of the service perimeter."
  type        = string
  default     = "fin-ctp-security"
}
