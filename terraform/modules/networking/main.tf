# Networking Module - VPC and Subnets (Air-Gapped Configuration)
# Cloud Router and Cloud NAT removed to save $32/month per project
# Jenkins uses pre-built image, no internet access needed

resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  project                 = var.project_id
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
  project       = var.project_id

  # Keep private Google access for GCP APIs (Cloud Logging, Monitoring, etc.)
  private_ip_google_access = true
}

# Cloud Router and Cloud NAT REMOVED for air-gapped deployment
# Savings: ~$32/month per project = $64/month total
# Jenkins deployed from custom image with everything pre-installed
# No internet access required or provided

