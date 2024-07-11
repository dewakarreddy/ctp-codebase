variable "project_id" {
  description = "The ID of the project to create the resources in."
  default     = "ctp-prj-1"
}

variable "region" {
  description = "The region where resources will be created."
  default     = "us-central1"
}

variable "zone" {
  description = "The zone where resources will be created."
  default     = "us-central1-a"
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
  type        = number
}

variable "new_num_nodes" {
  description = "The new number of nodes for the Bigtable cluster (for partial update)"
  type        = number
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

variable "backup_id" {
  description = "The ID of the Bigtable backup."
  type        = string
}

variable "source_backup" {
  description = "The source backup to copy from."
  type        = string
}

variable "expire_time" {
  description = "The expiration time of the backup."
  type        = string
}

variable "iam_role" {
  description = "The IAM role to set."
  type        = string
}

variable "iam_members" {
  description = "The IAM members to assign the role."
  type        = list(string)
}

variable "permissions" {
  description = "The list of permissions to test."
  type        = list(string)
}

variable "parent_project" {
  description = "The parent project for creating resources."
  type        = string
}

variable "resource_name" {
  description = "The resource name for various operations."
  type        = string
  default     = "operations/operation-id"
}
