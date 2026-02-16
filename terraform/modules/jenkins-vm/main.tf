# Jenkins VM Module - Air-Gapped Configuration
# Uses custom image with Jenkins pre-installed
# No internet access required

# Data disk for Jenkins
resource "google_compute_disk" "jenkins_data" {
  name    = "jenkins-data-disk"
  type    = "pd-standard"
  size    = var.data_disk_size
  zone    = var.zone
  project = var.project_id

  labels = {
    environment = "production"
    application = "jenkins"
    deployment  = "airgapped"
  }
}

# Jenkins VM Instance
resource "google_compute_instance" "jenkins" {
  name         = "jenkins-vm"
  machine_type = var.machine_type
  zone         = var.zone
  project      = var.project_id

  tags = ["jenkins-server", "allow-iap-ssh"]

  boot_disk {
    initialize_params {
      # Temporarily using standard Rocky Linux 8 image
      # Will switch to air-gapped image after creation
      image = "rocky-linux-cloud/rocky-linux-8"
      size  = var.boot_disk_size
      type  = "pd-standard"
    }
  }

  attached_disk {
    source      = google_compute_disk.jenkins_data.id
    device_name = "jenkins-data"
    mode        = "READ_WRITE"
  }

  network_interface {
    subnetwork = var.subnet_name
    network_ip = "10.10.10.10"
    # No external IP - completely private
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  # Startup script to install Jenkins (using external file with correct line endings)
  metadata_startup_script = file("${path.root}/../scripts/jenkins-startup.sh")

  service_account {
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write"
    ]
  }

  lifecycle {
    ignore_changes = [
      metadata_startup_script
    ]
  }

  labels = {
    environment = "production"
    application = "jenkins"
    deployment  = "airgapped"
  }
}

# Firewall rule: IAP SSH access
resource "google_compute_firewall" "jenkins_iap_ssh" {
  name    = "jenkins-iap-ssh"
  network = var.vpc_name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["jenkins-server"]

  description = "Allow SSH access from Google IAP"
}

# Firewall rule: VPN access to Jenkins
resource "google_compute_firewall" "jenkins_vpn_access" {
  name    = "allow-vpn-to-jenkins"
  network = var.vpc_name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["8080", "443"]
  }

  source_ranges = [var.vpn_subnet_cidr]
  target_tags   = ["jenkins-server"]

  description = "Allow Jenkins access from VPN subnet"
}

# Firewall rule: Health check access
resource "google_compute_firewall" "jenkins_health_check" {
  name    = "jenkins-health-check"
  network = var.vpc_name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22"
  ]
  target_tags = ["jenkins-server"]

  description = "Allow health checks from GCP load balancers"
}
