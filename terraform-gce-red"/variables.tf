/*
 * variables.tf
 * 
 * This Terraform variables file defines the configurable parameters for the GCP infrastructure. The parameters include:
 * - Project ID, region, and zone settings for the GCP project.
 * - Instance-specific configurations including instance name, machine type, and boot disk settings.
 * - SSH username and public key for accessing the instances.
 * - Startup script to be executed on instance initialization.
 * - Tags and labels for the instances.
 * - Additional disks configuration for the instance to attach extra storage.
 * - Service accounts and their scopes for accessing GCP services.
 * - Metadata and OS Login settings.
 * - Stackdriver logging and monitoring configurations.
 * - Bigtable instance and table configurations.
 */

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "europe-west1"
}

variable "zone" {
  description = "The GCP zone"
  type        = string
  default     = "europe-west1-b"
}

# Variables for the complex instance (now named instance-4)
variable "instance_4_name" {
  description = "The name of the instance"
  type        = string
  default     = "instance-4"
}

variable "machine_type" {
  description = "The machine type for the instance"
  type        = string
  default     = "n1-standard-4"
}

variable "boot_disk_size" {
  description = "The size of the boot disk for the instance in GB"
  type        = number
  default     = 50
}

variable "boot_disk_type" {
  description = "The type of the boot disk for the instance"
  type        = string
  default     = "pd-ssd"
}

variable "boot_disk_encryption" {
  description = "The encryption key for the boot disk of the instance"
  type        = string
  default     = null
}

variable "preemptible" {
  description = "Whether the instance is preemptible"
  type        = bool
  default     = false
}

variable "ssh_username" {
  description = "The SSH username"
  type        = string
}

variable "ssh_public_key" {
  description = "The SSH public key"
  type        = string
}

variable "startup_script" {
  description = "The startup script"
  type        = string
  default     = <<-EOF
    #!/bin/bash
    echo "Running startup script"
    apt-get update
    apt-get install -y apache2
    systemctl start apache2
    systemctl enable apache2
  EOF
}

variable "tags" {
  description = "Tags for the instance"
  type        = list(string)
  default     = ["web-server"]
}

variable "labels" {
  description = "Labels for the instance"
  type        = map(string)
  default     = {
    environment = "dev"
    team        = "secops"
  }
}

variable "additional_disks" {
  description = "Additional disks configuration for the instance"
  type = list(object({
    name = string
    size = number
    type = string
    zone = string
  }))
  default = [
    {
      name = "additional-disk-1"
      size = 200
      type = "pd-standard"
      zone = "europe-west1-b"
    },
    {
      name = "additional-disk-2"
      size = 100
      type = "pd-standard"
      zone = "europe-west1-b"
    }
  ]
}

variable "service_accounts" {
  description = "Service accounts configuration"
  type = list(object({
    email  = string
    scopes = list(string)
  }))
  default = [
    {
      email  = "default"
      scopes = ["https://www.googleapis.com/auth/cloud-platform"]
    }
  ]
}

variable "metadata" {
  description = "Additional metadata for the instance"
  type        = map(string)
  default     = {
    enable-oslogin = "TRUE"
    block-project-ssh-keys = "TRUE"
  }
}

variable "stackdriver_logging" {
  description = "Enable Stackdriver logging"
  type        = bool
  default     = true
}

variable "stackdriver_monitoring" {
  description = "Enable Stackdriver monitoring"
  type        = bool
  default     = true
}

# Variables for Bigtable instance
variable "bigtable_instance_name" {
  description = "The name of the Bigtable instance"
  type        = string
  default     = "bigtable-instance"
}

variable "bigtable_instance_type" {
  description = "The type of the Bigtable instance (PRODUCTION or DEVELOPMENT)"
  type        = string
  default     = "PRODUCTION"
}

variable "bigtable_cluster_id" {
  description = "The ID of the Bigtable cluster"
  type        = string
  default     = "bigtable-cluster"
}

variable "bigtable_num_nodes" {
  description = "The number of nodes in the Bigtable cluster (only for PRODUCTION instances)"
  type        = number
  default     = 1
}

variable "bigtable_table_name" {
  description = "The name of the Bigtable table"
  type        = string
  default     = "bigtable-table"
}

variable "bigtable_column_family" {
  description = "The column family name in the Bigtable table"
  type        = string
  default     = "cf1"
}
