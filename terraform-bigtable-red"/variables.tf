variable "project_id" {
  description = "The ID of the project to create the resources in."
  default     = "ctp-prj-1"
}

variable "region" {
  description = "The region where resources will be created."
  default     = "europe-west1"
}

variable "zone" {
  description = "The zone where resources will be created."
  default     = "europe-west1-b"
}

variable "instance_name" {
  description = "The name of the Bigtable instance."
  default     = "ctp-bigtable-instance"
}

variable "cluster_id" {
  description = "The ID of the Bigtable cluster."
  default     = "ctp-cluster"
}

variable "num_nodes" {
  description = "The number of nodes in the Bigtable cluster."
  default     = 3
}

variable "storage_type" {
  description = "The storage type for the Bigtable cluster."
  default     = "HDD"
}

variable "app_profile_id" {
  description = "The ID of the Bigtable app profile."
  default     = "ctp-app-profile"
}

variable "table_name" {
  description = "The name of the Bigtable table."
  default     = "ctp-table"
}

variable "backup_name" {
  description = "The name of the Bigtable backup."
  default     = "ctp-backup"
}

variable "operation_name" {
  description = "The name of the long-running operation."
  default     = "ctp-operation"
}

variable "network" {
  description = "The name or self_link of the network to attach this interface to."
  default     = "default"
}

variable "subnetwork" {
  description = "The name or self_link of the subnetwork to attach this interface to."
  default     = "default"
}
