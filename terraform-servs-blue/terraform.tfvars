project_id                 = "ctp-prj-1"
region                     = "europe-west1"
zone                       = "europe-west1-d"
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
service_accounts = [
  {
    email  = "default"
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
]

disk_name             = "example-disk"
description           = "Example disk description"
sizeGb                = 100
new_sizeGb            = 200
type                  = "pd-standard"
labels                = {
  environment = "test",
  owner       = "devops"
}
resource_policies     = ["policy-1", "policy-2"]
new_description       = "Updated example disk description"

image_name            = "example-image"
image_family          = "debian-11" # Ensure this family exists in your project
image_labels          = {
  environment = "test"
  owner       = "devops"
}
image_new_description = "Updated example image description"

