/*
 * terraform.tfvars
 * 
 * This Terraform variables file provides specific values for the configurable parameters defined in variables.tf. It includes:
 * - Project-specific details such as project ID, region, and zone.
 * - Instance-specific configurations including names, machine types, and boot disk sizes.
 * - SSH username and public key for accessing the instances.
 * - Additional disks configurations for instance 1 and instance 2.
 * - Service accounts and their scopes for accessing GCP services.
 * 
 * This file allows for easy customization and management of the infrastructure settings.
 */

project_id                 = "ctp-prj-1"
region                     = "us-central1"
zone                       = "us-central1-a"
storage_bucket_name         = "your-log-bucket-name" # Optional: can be omitted to use the default name
network                    = "vpc-001"
subnetwork                 = "subnetwork-001"
peer_ip                    = "35.209.144.217"
shared_secret              = "ctp-vpn-tunnel"
vpn_gateway_name           = "ctp-vpn-us"
vpn_tunnel_name            = "ctp-tunnel-us"
instance_1_name            = "instance-1"
instance_1_machine_type    = "n1-standard-4"
instance_1_boot_disk_size  = 50
instance_1_boot_disk_type  = "pd-ssd"
instance_1_preemptible     = false
instance_2_name            = "instance-2"
instance_2_machine_type    = "n1-highmem-4"
instance_2_boot_disk_size  = 100
instance_2_boot_disk_type  = "pd-standard"
instance_2_preemptible     = false
instance_3_name            = "instance-3"
instance_3_machine_type    = "n1-standard-1"
instance_3_boot_disk_size = 10
instance_3_boot_disk_type = "pd-standard"
ssh_username               = "dewakarreddy@google.com"
ssh_public_key             = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCeb3KMO6Byn6XjpHJQKRbPuFYKXPKTXcOJLtxntWHOxuLl6i6+SN9t/yYPaygWOWnPl9p5L/UchKkFSryiCKCXsQYfakmNJLtuvtpYd09MOu4sgtDYOxCD4vWblHuhBdXpqXx2a175F8gM7sCQYEfRaySjHUsdCEI5SaOJVYqCQSOq5CHc1fVB7SNYTlxFForsNyDObFgiJ7eDAWZa5o8bbkbxxN1WlI5F0YzS+Yiwf938dvAqK2yM9UExg42nEgd/yfZ8IvOzLNEvkESCDXuh0CsnTT6JMBoUHOb1Ts2zbHGFOkq+2G001Sy3FhVAgX3Y9ZfMlBDoNEqqSIVGz7P9 dewakarreddy@google.com"

additional_disks = [
  {
    name = "additional-disk-1"
    size = 200
    type = "pd-standard"
    zone = "us-central1-a"
  },
  {
    name = "additional-disk-2"
    size = 100
    type = "pd-standard"
    zone = "us-central1-a"
  }
]

service_accounts = [
  {
    email  = "default"
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
]

