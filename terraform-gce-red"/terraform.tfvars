# terraform.tfvars
# This file contains the variable values for the Terraform configuration.
# Adjust the values according to your specific requirements.

project_id = "ctp-prj-1"

# Region and Zone settings
region = "europe-west1"
zone   = "europe-west1-b"

# Instance-specific configurations
instance_4_name   = "instance-4"
machine_type      = "n1-standard-4"
boot_disk_size    = 50
boot_disk_type    = "pd-ssd"
boot_disk_encryption = null
preemptible       = false

# SSH settings
ssh_username      = "dewakarreddy@google.com"
ssh_public_key    = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCeb3KMO6Byn6XjpHJQKRbPuFYKXPKTXcOJLtxntWHOxuLl6i6+SN9t/yYPaygWOWnPl9p5L/UchKkFSryiCKCXsQYfakmNJLtuvtpYd09MOu4sgtDYOxCD4vWblHuhBdXpqXx2a175F8gM7sCQYEfRaySjHUsdCEI5SaOJVYqCQSOq5CHc1fVB7SNYTlxFForsNyDObFgiJ7eDAWZa5o8bbkbxxN1WlI5F0YzS+Yiwf938dvAqK2yM9UExg42nEgd/yfZ8IvOzLNEvkESCDXuh0CsnTT6JMBoUHOb1Ts2zbHGFOkq+2G001Sy3FhVAgX3Y9ZfMlBDoNEqqSIVGz7P9 dewakarreddy@google.com"

# Startup script for the VM instance
startup_script = <<-EOF
  #!/bin/bash
  echo "Running startup script"
  apt-get update
  apt-get install -y apache2
  systemctl start apache2
  systemctl enable apache2

  # Install the Google Cloud Logging agent
  curl -sSO https://dl.google.com/cloudagents/add-logging-agent-repo.sh
  bash add-logging-agent-repo.sh
  apt-get update
  apt-get install -y google-fluentd
  service google-fluentd start
  # Enable error logging
  cat <<EOF2 > /etc/google-fluentd/config.d/apache2.conf
<source>
  @type tail
  format apache2
  path /var/log/apache2/error.log
  pos_file /var/lib/google-fluentd/pos/apache2-error-log.pos
  read_from_head true
  tag apache2-error
</source>
EOF2
  service google-fluentd restart
EOF

# Tags and labels for the VM instance
tags = ["web-server"]
labels = {
  environment = "dev"
  team        = "secops"
}

# Additional disks configuration for the VM instance
additional_disks = [
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

# Service accounts configuration
service_accounts = [
  {
    email  = "default"
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
]

# Metadata settings for the VM instance
metadata = {
  enable-oslogin = "TRUE"
  block-project-ssh-keys = "TRUE"
}

# Stackdriver logging and monitoring settings
stackdriver_logging = true
stackdriver_monitoring = true

# Bigtable instance configuration
bigtable_instance_name = "bigtable-instance"
bigtable_instance_type = "PRODUCTION"
bigtable_cluster_id    = "bigtable-cluster"
bigtable_num_nodes     = 1

# Bigtable table configuration
bigtable_table_name    = "bigtable-table"
bigtable_column_family = "cf1"
