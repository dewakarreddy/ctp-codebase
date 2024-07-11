/*
 * variables.tf
 * 
 * This Terraform variables file defines the configurable parameters for the GCP infrastructure. The parameters include:
 * - Project ID, region, and zone settings for the GCP project.
 * - Instance-specific configurations for three instances (instance_1, instance_2, and instance_3), such as instance names, machine types, and boot disk settings.
 * - SSH username and public key for accessing the instances.
 * - Startup script to be executed on instance initialization.
 * - Tags and labels for the instances.
 * - Additional disks configuration for instances to attach extra storage.
 * - Service accounts and their scopes for accessing GCP services.
 * 
 * The use of variables allows for flexibility and easy customization of the infrastructure.
 */


variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "storage_bucket_name" {
  description = "The name of the storage bucket to store logs."
  type        = string
  default     = null
}

variable "zone" {
  description = "The GCP zone"
  type        = string
  default     = "us-central1-a"
}

# Variables for the first instance
variable "instance_1_name" {
  description = "The name of the first instance"
  type        = string
  default     = "instance-1"
}

variable "instance_1_new_name" {
  description = "The new name for the first instance"
  type        = string
  default     = "ctp-instance-1"
}

variable "instance_1_machine_type" {
  description = "The machine type for the first instance"
  type        = string
  default     = "n1-standard-4"
}

variable "instance_1_boot_disk_size" {
  description = "The size of the boot disk for the first instance in GB"
  type        = number
  default     = 50
}

variable "instance_1_boot_disk_type" {
  description = "The type of the boot disk for the first instance"
  type        = string
  default     = "pd-ssd"
}

variable "instance_1_preemptible" {
  description = "Whether the first instance is preemptible"
  type        = bool
  default     = false
}

# Shared variables
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
  description = "Tags for the instances"
  type        = list(string)
  default     = ["web-server"]
}

variable "labels" {
  description = "Labels for the instances"
  type        = map(string)
  default     = {
    environment = "dev"
    team        = "devops"
  }
}

variable "additional_disks_instance_1" {
  description = "Additional disks configuration for instance 1"
  type = list(object({
    name = string
    size = number
    type = string
    zone = string
  }))
  default = [
    {
      name = "instance-1-disk-1"
      size = 200
      type = "pd-standard"
      zone = "us-central1-a"
    },
    {
      name = "instance-1-disk-2"
      size = 100
      type = "pd-standard"
      zone = "us-central1-a"
    }
  ]
}

variable "zones" {
  type = list(string)
  default = ["us-central1-a", "us-central1-b"]
}

variable "disk_types" {
  type = map(string)
  default = {
    "us-central1-a" = "pd-standard"
    "us-central1-b" = "pd-ssd"
  }
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


#VPN Tuneels
variable "network" {
  description = "The VPC network name"
  type        = string
}

variable "subnetwork" {
  description = "The subnetwork name"
  type        = string
}

variable "peer_ip" {
  description = "The IP address of the peer VPN gateway"
  type        = string
}

variable "shared_secret" {
  description = "The shared secret for the VPN tunnel"
  type        = string
}

variable "vpn_gateway_name" {
  description = "The name of the VPN gateway"
  type        = string
}

variable "vpn_tunnel_name" {
  description = "The name of the VPN tunnel"
  type        = string
}

variable "local_traffic_selector" {
  description = "Local traffic selector for the VPN tunnel"
  type        = list(string)
  default     = ["10.0.0.0/24"] # Adjust this to match your specific subnetworks
}

variable "service_account_email" {
  description = "The email of the service account to attach to the instance"
  type        = string
  default     = "dewakarreddy@google.com"
}

variable "service_account_scopes" {
  description = "The scopes to assign to the service account"
  type        = list(string)
  default     = ["https://www.googleapis.com/auth/cloud-platform"]
}
