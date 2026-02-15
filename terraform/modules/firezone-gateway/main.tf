# Firezone Gateway Module

# Firezone Gateway VM
resource "google_compute_instance" "firezone_gateway" {
  name         = "firezone-gateway"
  machine_type = var.machine_type
  zone         = var.zone
  project      = var.project_id

  tags = ["firezone-gateway", "allow-vpn"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = var.subnet_name

    access_config {
      # Ephemeral public IP for VPN access
    }
  }

  metadata = {
    enable-oslogin = "TRUE"
    firezone-token = var.firezone_token
  }

  metadata_startup_script = templatefile("${path.module}/scripts/firezone-install.sh", {
    firezone_token = var.firezone_token
  })

  service_account {
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write"
    ]
  }
}

# Firewall rule: Allow VPN traffic
resource "google_compute_firewall" "firezone_vpn" {
  name    = "firezone-vpn-traffic"
  network = var.vpc_name
  project = var.project_id

  allow {
    protocol = "udp"
    ports    = ["51820"]
  }

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["firezone-gateway"]

  description = "Allow VPN traffic to Firezone gateway"
}

# Firewall rule: Egress to Project 2
resource "google_compute_firewall" "firezone_egress" {
  name      = "firezone-to-jenkins-egress"
  network   = var.vpc_name
  project   = var.project_id
  direction = "EGRESS"

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  destination_ranges = ["10.10.10.0/24"]
  target_tags        = ["firezone-gateway"]

  description = "Allow egress from Firezone to Jenkins subnet"
}
