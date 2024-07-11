/*
 * main.tf
 * 
 * This Terraform configuration file sets up a comprehensive Google Cloud Platform (GCP) infrastructure. It includes:
 * 
 * - Firewall rules to allow traffic on ports 22 (SSH), 80 (HTTP), and 443 (HTTPS), and allow load balancer health checks.
 * - Health checks and instance groups to integrate with a load balancer for high availability.
 * - Google Compute Engine (GCE) instance with complex configurations:
 *   - instance_1: A complex instance with multiple attached disks, specific configurations, and metadata.
 * - Static IP addresses assigned to the instance to provide fixed external IPs.
 * - Metadata for SSH keys, startup scripts to install and start Apache web servers, and enabling OS Login for secure SSH access.
 * - Shielded VM configurations for enhanced security, including secure boot, virtual TPM, and integrity monitoring.
 * - Dynamic blocks for attaching additional disks and service accounts to the instance, allowing for flexible configurations.
 * - Instance templates and instance groups for managing similar instances and integrating with load balancers.
 * - Outputs to display the external IP addresses of the instance for easy access.
 * - Installation of OS Config Agent for enhanced management.
 * - Configuration of NIC type.
 * - Autoscaling policies for instance groups.
 * - Startup and shutdown scripts for custom actions.
 *
 * Variables are used extensively to allow customization of instance configurations, such as machine type, boot disk size, additional disks, and more.
 */

# Define the GCP provider
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Create firewall rule to allow SSH, HTTP, and HTTPS traffic
resource "google_compute_firewall" "priority100" {
  name    = "priority100"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Create firewall rule to allow HTTPS traffic
resource "google_compute_firewall" "https_firewall" {
  name    = "https-firewall"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Create firewall rule to allow load balancer health checks
resource "google_compute_firewall" "allow_lb_health_checks" {
  name    = "allow-lb-health-checks"
  network = var.network

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
resource "google_compute_instance_template" "instance_template" {
  name_prefix    = "web-instance-template-"
  machine_type   = var.instance_1_machine_type
  can_ip_forward = false

  disk {
    source_image = "projects/debian-cloud/global/images/family/debian-10"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork
    
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
  name            = "backend-service-unique"
  health_checks   = [google_compute_http_health_check.default.self_link]
  backend {
    group = google_compute_instance_group_manager.webservers.self_link
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
resource "google_compute_resource_policy" "snapshot_policy" {
  name   = "daily-snapshot-policy"
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
      image = "projects/debian-cloud/global/images/family/debian-10"
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
    network    = var.network
    subnetwork = var.subnetwork
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

  dynamic "service_account" {
    for_each = { for sa in var.service_accounts : sa.email => sa }
    content {
      email  = service_account.value.email
      scopes = service_account.value.scopes
    }
  }
}

# Create snapshots of all instance_1 attached disks
resource "google_compute_snapshot" "instance_1_disk_snapshot" {
  for_each    = google_compute_disk.instance_1_attached_disk
  name        = "${each.key}-snapshot"
  source_disk = each.value.self_link
  zone        = var.zone
}

# Get information about instance_1
data "google_compute_instance" "instance_1_info" {
  name = google_compute_instance.instance_1.name
  zone = var.zone
}

output "instance_1_self_link" {
  value = data.google_compute_instance.instance_1_info.self_link
}

# Output the external IP address of the instance
output "instance_1_ip" {
  value = google_compute_instance.instance_1.network_interface[0].access_config[0].nat_ip
}
