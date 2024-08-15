provider "google-beta" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Ensure logging.googleapis.com service is enabled
resource "google_project_service" "logging" {
  project = var.project_id
  service = "logging.googleapis.com"

  disable_on_destroy = false

  lifecycle {
    ignore_changes = [
      disable_on_destroy
    ]
  }
}

# Create a custom VPC network
resource "google_compute_network" "vpc_network" {
  name = "vpc-001"

  lifecycle {
    precondition {
      condition     = var.create_vpc == "true"
      error_message = "User did not confirm the creation of the VPC network"
    }
  }
}

# Create a custom subnetwork within the VPC
resource "google_compute_subnetwork" "subnetwork" {
  name          = "subnet-001"
  network       = google_compute_network.vpc_network.id
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region

  lifecycle {
    precondition {
      condition     = var.create_subnet == "true"
      error_message = "User did not confirm the creation of the subnetwork"
    }
  }
}

# Create firewall rules
resource "google_compute_firewall" "priority100" {
  name    = "priority100"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_lb_health_checks" {
  name    = "allow-lb-health-checks"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["allow-health-check"]
}

# Define a health check for the load balancer
resource "google_compute_http_health_check" "default" {
  name               = "http-basic-check"
  request_path       = "/"
  check_interval_sec = 5
  timeout_sec        = 5
}

# Create an instance template for similar instances
data "google_compute_image" "debian" {
  family  = "debian-11"
  project = "debian-cloud"
}

resource "google_compute_instance_template" "instance_template" {
  name_prefix    = "web-instance-template-"
  machine_type   = var.instance_1_machine_type
  can_ip_forward = false

  disk {
    source_image = data.google_compute_image.debian.self_link
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.subnetwork.id

    access_config {
      // Ephemeral IP
    }
  }

  metadata = {
    enable-oslogin = "TRUE"
    startup-script = "sudo apt-get install -y google-osconfig-agent"
  }

  scheduling {
    preemptible       = false
    on_host_maintenance = "MIGRATE"
  }
}

# Create a managed instance group
resource "google_compute_instance_group_manager" "webservers" {
  name               = "web-server-group"
  zone               = var.zone
  base_instance_name = "web-server"
  target_size        = 3

  version {
    instance_template = google_compute_instance_template.instance_template.self_link
  }

  named_port {
    name = "http"
    port = 80
  }

  auto_healing_policies {
    health_check      = google_compute_http_health_check.default.self_link
    initial_delay_sec = 300
  }
}

# Define an autoscaler for the instance group
resource "google_compute_autoscaler" "web_autoscaler" {
  name   = "web-autoscaler"
  zone   = var.zone
  target = google_compute_instance_group_manager.webservers.self_link

  autoscaling_policy {
    max_replicas    = 10
    min_replicas    = 1
    cooldown_period = 60

    cpu_utilization {
      target = 0.6
    }
  }
}

# Create a global address for the load balancer
resource "google_compute_global_address" "default" {
  name = "global-address"
}

# Create a backend service for the load balancer
resource "google_compute_backend_service" "default" {
  name          = "backend-service-unique"
  health_checks = [google_compute_http_health_check.default.self_link]
  backend {
    group = google_compute_instance_group_manager.webservers.instance_group
  }
}

# Create a URL map for the load balancer
resource "google_compute_url_map" "default" {
  name            = "url-map"
  default_service = google_compute_backend_service.default.self_link
}

# Create a target HTTP proxy for the load balancer
resource "google_compute_target_http_proxy" "default" {
  name    = "http-proxy"
  url_map = google_compute_url_map.default.self_link
}

# Create a global forwarding rule for the load balancer
resource "google_compute_global_forwarding_rule" "default" {
  name       = "http-rule"
  target     = google_compute_target_http_proxy.default.self_link
  port_range = "80"
  ip_address = google_compute_global_address.default.address
}

# Reserve static IP address for the instance
resource "google_compute_address" "instance_1_ip" {
  name   = "${var.instance_1_name}-ip"
  region = var.region
}

# Adding Resource Policy for snapshots
resource "google_compute_resource_policy" "policy_1" {
  name   = "policy-1"
  region = var.region

  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = "03:00"
      }
    }

    retention_policy {
      max_retention_days    = 7
      on_source_disk_delete = "KEEP_AUTO_SNAPSHOTS"
    }
  }
}

resource "google_compute_resource_policy" "policy_2" {
  name   = "policy-2"
  region = var.region

  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = "03:00"
      }
    }

    retention_policy {
      max_retention_days    = 7
      on_source_disk_delete = "KEEP_AUTO_SNAPSHOTS"
    }
  }
}

# Define the Google Compute Disk
resource "google_compute_disk" "example_disk" {
  name        = var.disk_name
  description = var.description
  size        = var.sizeGb
  type        = var.type
  zone        = var.zone
}

# Attach Resource Policies to the Disk
resource "google_compute_disk_resource_policy_attachment" "example_attachment" {
  count = length(var.resource_policies)
  disk  = google_compute_disk.example_disk.name
  zone  = var.zone
  name  = element(var.resource_policies, count.index)
}

# Set IAM Policy for the Disk
resource "google_compute_disk_iam_binding" "example_iam_binding" {
  name = google_compute_disk.example_disk.name
  role = "roles/compute.storageAdmin"

  members = [
    "user:dewakarreddy@google.com",
  ]
}

# Set Labels for the Disk
resource "google_compute_disk" "example_disk_labels" {
  name        = google_compute_disk.example_disk.name
  description = var.description
  size        = var.sizeGb
  type        = var.type
  zone        = var.zone
  labels      = var.labels
}

# Return Permissions on the Disk
data "google_compute_disk_iam_policy" "example_permissions" {
  name = google_compute_disk.example_disk.name
}

# Attach Disk to Instance
resource "google_compute_attached_disk" "example_attached_disk" {
  instance = google_compute_instance.instance_1.name
  disk     = google_compute_disk.example_disk.name
  zone     = var.zone
}

# Define additional disks for instance_1
resource "google_compute_disk" "instance_1_attached_disk" {
  for_each = { for disk in var.additional_disks_instance_1 : disk.name => disk }

  name  = each.value.name
  type  = each.value.type
  zone  = each.value.zone
  size  = each.value.size
}

# Define the first compute instance with Debian and Apache
resource "google_compute_instance" "instance_1" {
  name                 = var.instance_1_name
  machine_type         = var.instance_1_machine_type
  zone                 = var.zone
  deletion_protection  = false
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian.self_link
      size  = var.instance_1_boot_disk_size
      type  = var.instance_1_boot_disk_type
    }
  }

  dynamic "attached_disk" {
    for_each = { for disk in var.additional_disks_instance_1 : disk.name => disk }
    content {
      source = google_compute_disk.instance_1_attached_disk[attached_disk.key].id
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.subnetwork.id
    nic_type   = "VIRTIO_NET"

    access_config {
      nat_ip = google_compute_address.instance_1_ip.address
    }
  }

  metadata = {
    ssh-keys       = "${var.ssh_username}:${var.ssh_public_key}"
    startup-script = <<-EOT
      #!/bin/bash
      sudo apt-get update
      sudo apt-get install -y google-osconfig-agent
      sudo apt-get install -y apache2
      sudo systemctl start apache2
    EOT
    shutdown-script = <<-EOT
      #!/bin/bash
      echo "Shutdown script executed at $(date)" >> /var/log/shutdown-script.log
    EOT
    enable-oslogin = "TRUE"
  }

  tags = var.tags

  labels = var.labels

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  scheduling {
    preemptible         = var.instance_1_preemptible
    on_host_maintenance = "MIGRATE"
    automatic_restart   = true
  }
}

# Create snapshots of all instance_1 attached disks
resource "google_compute_snapshot" "instance_1_disk_snapshot" {
  for_each    = google_compute_disk.instance_1_attached_disk
  name        = "${each.key}-snapshot"
  source_disk = each.value.self_link
  zone        = var.zone
}

# Example of creating a snapshot of a disk
resource "google_compute_snapshot" "example_snapshot" {
  name        = "example-snapshot"
  source_disk = google_compute_disk.example_disk.self_link
  zone        = var.zone
}

# Example of resizing a disk
resource "null_resource" "resize_disk" {
  provisioner "local-exec" {
    command = "gcloud compute disks resize ${google_compute_disk.example_disk.name} --size 200 --zone ${var.zone}"
  }
  depends_on = [google_compute_disk.example_disk]
}

# Example of detaching a disk
resource "null_resource" "detach_disk" {
  provisioner "local-exec" {
    command = <<EOT
      gcloud compute instances detach-disk ${google_compute_instance.instance_1.name} --disk=${google_compute_disk.example_disk.name} --zone=${var.zone}
    EOT
  }
  depends_on = [google_compute_instance.instance_1, google_compute_disk.example_disk]
}

# Example of retrieving an aggregated list of all instances
resource "null_resource" "aggregated_list_instances" {
  provisioner "local-exec" {
    command = "gcloud compute instances list --project ${var.project_id}"
  }
  depends_on = [google_compute_instance.instance_1]
}

# Example of getting information about a specified instance
resource "null_resource" "get_instance" {
  provisioner "local-exec" {
    command = "gcloud compute instances describe ${google_compute_instance.instance_1.name} --zone ${var.zone}"
  }
  depends_on = [google_compute_instance.instance_1]
}

# Example of getting effective firewalls applied to an instance
resource "null_resource" "get_effective_firewalls" {
  provisioner "local-exec" {
    command = "gcloud compute instances describe ${google_compute_instance.instance_1.name} --zone ${var.zone} --format='json(networkInterfaces.effectiveFirewalls)'"
  }
  depends_on = [google_compute_instance.instance_1]
}

# Example of getting guest attributes for a specified instance
resource "null_resource" "get_guest_attributes" {
  provisioner "local-exec" {
    command = "gcloud compute instances get-guest-attributes ${google_compute_instance.instance_1.name} --zone ${var.zone}"
  }
  depends_on = [google_compute_instance.instance_1]
}

# Example of getting the access control policy for a resource
resource "null_resource" "get_instance_iam_policy" {
  provisioner "local-exec" {
    command = "gcloud compute instances get-iam-policy ${google_compute_instance.instance_1.name} --zone ${var.zone}"
  }
  depends_on = [google_compute_instance.instance_1]
}

# Example of getting serial port output from a specified instance
resource "null_resource" "get_serial_port_output" {
  provisioner "local-exec" {
    command = "gcloud compute instances get-serial-port-output ${google_compute_instance.instance_1.name} --zone ${var.zone}"
  }
  depends_on = [google_compute_instance.instance_1]
}

# Example of getting Shielded Instance Identity of an instance
resource "null_resource" "get_shielded_instance_identity" {
  provisioner "local-exec" {
    command = "gcloud compute instances get-shielded-identity ${google_compute_instance.instance_1.name} --zone ${var.zone}"
  }
  depends_on = [google_compute_instance.instance_1]
}

# Example of setting network tags for an instance
resource "null_resource" "set_tags" {
  provisioner "local-exec" {
    command = "gcloud compute instances add-tags ${google_compute_instance.instance_1.name} --zone ${var.zone} --tags http-server,https-server"
  }
  depends_on = [google_compute_instance.instance_1]
}

# Create the VPN gateway
resource "google_compute_vpn_gateway" "vpn_gateway" {
  name    = var.vpn_gateway_name
  network = google_compute_network.vpc_network.self_link
  region  = var.region
}

# Create a static IP for the VPN gateway
resource "google_compute_address" "vpn_gateway_ip" {
  name   = "vpn-gateway-ip"
  region = var.region
}

# Create a forwarding rule for ESP traffic
resource "google_compute_forwarding_rule" "esp_forwarding_rule" {
  name        = "esp-forwarding-rule"
  region      = var.region
  ip_address  = google_compute_address.vpn_gateway_ip.address
  target      = google_compute_vpn_gateway.vpn_gateway.self_link
  ip_protocol = "ESP"
}

# Create a forwarding rule for UDP 500 traffic
resource "google_compute_forwarding_rule" "udp500_forwarding_rule" {
  name        = "udp500-forwarding-rule"
  region      = var.region
  ip_address  = google_compute_address.vpn_gateway_ip.address
  target      = google_compute_vpn_gateway.vpn_gateway.self_link
  ip_protocol = "UDP"
  port_range  = "500"
}

# Create a forwarding rule for UDP 4500 traffic
resource "google_compute_forwarding_rule" "udp4500_forwarding_rule" {
  name        = "udp4500-forwarding-rule"
  region      = var.region
  ip_address  = google_compute_address.vpn_gateway_ip.address
  target      = google_compute_vpn_gateway.vpn_gateway.self_link
  ip_protocol = "UDP"
  port_range  = "4500"
}

# Create the VPN tunnel
resource "google_compute_vpn_tunnel" "vpn_tunnel" {
  name              = var.vpn_tunnel_name
  region            = var.region
  target_vpn_gateway = google_compute_vpn_gateway.vpn_gateway.self_link
  peer_ip           = var.peer_ip
  shared_secret     = var.shared_secret
  local_traffic_selector = var.local_traffic_selector

  depends_on = [
    google_compute_vpn_gateway.vpn_gateway,
    google_compute_network.vpc_network,
    google_compute_subnetwork.subnetwork,
    google_compute_forwarding_rule.esp_forwarding_rule,
    google_compute_forwarding_rule.udp500_forwarding_rule,
    google_compute_forwarding_rule.udp4500_forwarding_rule
  ]
  lifecycle {
    create_before_destroy = true
  }
}

# Example of setting labels on a VPN tunnel
resource "google_compute_vpn_tunnel" "vpn_tunnel_labels" {
  name              = var.vpn_tunnel_name
  region            = var.region
  target_vpn_gateway = google_compute_vpn_gateway.vpn_gateway.self_link
  peer_ip           = var.peer_ip
  shared_secret     = var.shared_secret
  local_traffic_selector = var.local_traffic_selector

  labels = {
    environment = "production"
  }

  depends_on = [
    google_compute_vpn_gateway.vpn_gateway,
    google_compute_network.vpc_network,
    google_compute_subnetwork.subnetwork,
    google_compute_forwarding_rule.esp_forwarding_rule,
    google_compute_forwarding_rule.udp500_forwarding_rule,
    google_compute_forwarding_rule.udp4500_forwarding_rule
  ]
  lifecycle {
    create_before_destroy = true
  }
}

# Retrieve information about the VPN tunnel using the 'gcloud' command
resource "null_resource" "vpn_tunnel_info" {
  provisioner "local-exec" {
    command = "gcloud compute vpn-tunnels describe ${google_compute_vpn_tunnel.vpn_tunnel.name} --region ${var.region} --project ${var.project_id}"
  }

  depends_on = [google_compute_vpn_tunnel.vpn_tunnel]
}

# Define the Google Compute Image
resource "google_compute_image" "example_image" {
  name       = var.image_name
  source_disk = google_compute_disk.example_disk.self_link
}

# Deprecate Image using gcloud command
resource "null_resource" "deprecate_image" {
  provisioner "local-exec" {
    command = "gcloud compute images deprecate ${google_compute_image.example_image.name} --state DEPRECATED --project ${var.project_id}"
  }
  depends_on = [google_compute_image.example_image]
}

# Get Image from Family (Ensure family and project are correct)
data "google_compute_image" "image_from_family" {
  family  = var.image_family
  project = "debian-cloud"  # Use the public project for Debian images
}

# Set IAM Policy for the Image
resource "google_compute_image_iam_policy" "example_image_iam_policy" {
  image       = google_compute_image.example_image.name
  policy_data = data.google_iam_policy.example_image_policy.policy_data
}

data "google_iam_policy" "example_image_policy" {
  binding {
    role = "roles/compute.imageUser"
    members = [
      "user:dewakarreddy@google.com",
    ]
  }
}

# Set Labels for the Image
resource "google_compute_image" "example_image_labels" {
  name   = google_compute_image.example_image.name
  labels = var.image_labels
}

# Test IAM Permissions for Image using gcloud command
resource "null_resource" "test_image_permissions" {
  provisioner "local-exec" {
    command = "gcloud compute images get-iam-policy ${google_compute_image.example_image.name} --project ${var.project_id}"
  }
  depends_on = [google_compute_image.example_image]
}

# Patch Image
resource "google_compute_image" "example_image_patch" {
  name        = google_compute_image.example_image.name
  description = var.image_new_description
}

# Create a VM instance and machine image with encryption
resource "google_compute_instance" "vm" {
  provider     = google-beta
  name         = "my-vm"
  machine_type = "e2-medium"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
  }
}

resource "google_compute_machine_image" "image" {
  provider        = google-beta
  name            = "my-image"
  source_instance = google_compute_instance.vm.self_link
  machine_image_encryption_key {
    kms_key_name = google_kms_crypto_key.crypto_key.id
  }
}

resource "google_kms_crypto_key" "crypto_key" {
  provider = google-beta
  name     = "key"
  key_ring = google_kms_key_ring.key_ring.id
}

resource "google_kms_key_ring" "key_ring" {
  provider = google-beta
  name     = "keyring"
  location = "us"
}

# IAM policy for the machine image
data "google_iam_policy" "admin" {
  provider = google-beta
  binding {
    role = "roles/compute.admin"
    members = [
      "user:dewakarreddy@google.com",
    ]

    condition {
      title       = "expires_after_2024_12_31"
      description = "Expiring at midnight of 2024-12-31"
      expression  = "request.time < timestamp(\"2024-07-01T00:00:00Z\")"
    }
  }
}

resource "google_compute_machine_image_iam_policy" "policy" {
  provider = google-beta
  project = google_compute_machine_image.image.project
  machine_image = google_compute_machine_image.image.name
  policy_data = data.google_iam_policy.admin.policy_data
}

resource "google_compute_machine_image_iam_binding" "binding" {
  provider = google-beta
  project = google_compute_machine_image.image.project
  machine_image = google_compute_machine_image.image.name
  role = "roles/compute.admin"
  members = [
    "user:dewakarreddy@google.com",
  ]

  condition {
    title       = "expires_after_2024-12-31"
    description = "Expiring at midnight of 2024-12-31"
    expression  = "request.time < timestamp(\"2024-07-01T00:00:00Z\")"
  }
}

resource "google_compute_machine_image_iam_member" "member" {
  provider = google-beta
  project = google_compute_machine_image.image.project
  machine_image = google_compute_machine_image.image.name
  role = "roles/compute.admin"
  member = "user:dewakarreddy@google.com"

  condition {
    title       = "expires_after_2024-12-31"
    description = "Expiring at midnight of 2024-12-31"
    expression  = "request.time < timestamp(\"2024-07-01T00:00:00Z\")"
  }
}

# Create the interconnect
resource "google_compute_interconnect" "example_interconnect" {
  name                 = "example-interconnect"
  customer_name        = "example_customer"
  interconnect_type    = "DEDICATED"
  link_type            = "LINK_TYPE_ETHERNET_10G_LR"
  location             = "https://www.googleapis.com/compute/v1/projects/ctp-prj-1/global/interconnectLocations/iad-zone1-1"
  requested_link_count = 1
}

# Create the interconnect attachment
resource "google_compute_interconnect_attachment" "ipsec_encrypted_interconnect_attachment" {
  name                     = "test-interconnect-attachment"
  edge_availability_domain = "AVAILABILITY_DOMAIN_1"
  type                     = "PARTNER"
  router                   = google_compute_router.router.id
  encryption               = "IPSEC"
  ipsec_internal_addresses = [
    google_compute_address.address.self_link,
  ]
}

resource "google_compute_address" "address" {
  name          = "test-address"
  address_type  = "INTERNAL"
  purpose       = "IPSEC_INTERCONNECT"
  address       = "192.168.1.0"
  prefix_length = 29
  network       = google_compute_network.vpc_network.self_link
}

resource "google_compute_router" "router" {
  name                          = "test-router"
  network                       = google_compute_network.vpc_network.name
  encrypted_interconnect_router = true
  bgp {
    asn = 16550
  }
}

# Output the VPN tunnel details
output "vpn_tunnel_self_link" {
  value = google_compute_vpn_tunnel.vpn_tunnel.self_link
}

# Output the external IP address of the instance
output "instance_1_ip" {
  value = google_compute_instance.instance_1.network_interface[0].access_config[0].nat_ip
}

# Output the self link of the instance
output "instance_1_self_link" {
  value = google_compute_instance.instance_1.self_link
}

# Output the predefined disk types
output "predefined_disk_types" {
  value = var.disk_types
}
