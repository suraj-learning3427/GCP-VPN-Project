# Phase 1 Deployment - Core Infrastructure (without Firezone)
# This deploys VPCs, VPC Peering, DNS, Jenkins VM, and Load Balancer

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # backend "gcs" {
  #   bucket = "test-project1-485105-terraform-state"
  #   prefix = "vpn-jenkins-infrastructure/phase1"
  # }
}

# Provider for Project 1 (Networking)
provider "google" {
  alias   = "networking"
  project = var.project_id_networking
  region  = var.region
}

# Provider for Project 2 (Core IT)
provider "google" {
  alias   = "coreit"
  project = var.project_id_coreit
  region  = var.region
}

# Default provider
provider "google" {
  project = var.project_id_networking
  region  = var.region
}

# Module: Networking for Project 1
module "networking_project1" {
  source = "./modules/networking"

  providers = {
    google = google.networking
  }

  project_id  = var.project_id_networking
  region      = var.region
  vpc_name    = "networkingglobal-vpc"
  vpc_cidr    = "20.20.20.0/16"
  subnet_name = "vpn-subnet"
  subnet_cidr = "20.20.20.0/24"
}

# Module: Networking for Project 2
module "networking_project2" {
  source = "./modules/networking"

  providers = {
    google = google.coreit
  }

  project_id  = var.project_id_coreit
  region      = var.region
  vpc_name    = "core-it-vpc"
  vpc_cidr    = "10.10.10.0/16"
  subnet_name = "jenkins-subnet"
  subnet_cidr = "10.10.10.0/24"
}

# Module: VPC Peering
module "vpc_peering" {
  source = "./modules/vpc-peering"

  network_1_name      = module.networking_project1.vpc_name
  network_1_self_link = module.networking_project1.vpc_self_link
  network_2_name      = module.networking_project2.vpc_name
  network_2_self_link = module.networking_project2.vpc_self_link

  depends_on = [
    module.networking_project1,
    module.networking_project2
  ]
}

# Module: Jenkins VM
module "jenkins_vm" {
  source = "./modules/jenkins-vm"

  providers = {
    google = google.coreit
  }

  project_id      = var.project_id_coreit
  region          = var.region
  zone            = var.zone
  vpc_name        = module.networking_project2.vpc_name
  subnet_name     = module.networking_project2.subnet_name
  machine_type    = var.jenkins_vm_machine_type
  boot_disk_size  = var.jenkins_boot_disk_size
  data_disk_size  = var.jenkins_data_disk_size
  vpn_subnet_cidr = "20.20.20.0/24"

  depends_on = [module.networking_project2]
}

# Module: Internal Load Balancer
module "load_balancer" {
  source = "./modules/load-balancer"

  providers = {
    google = google.coreit
  }

  project_id       = var.project_id_coreit
  region           = var.region
  zone             = var.zone
  vpc_name         = module.networking_project2.vpc_name
  subnet_name      = module.networking_project2.subnet_name
  jenkins_instance = module.jenkins_vm.instance_self_link
  jenkins_hostname = var.jenkins_hostname

  depends_on = [module.jenkins_vm]
}

# Module: Private DNS
module "dns" {
  source = "./modules/dns"

  providers = {
    google = google.coreit
  }

  project_id       = var.project_id_coreit
  domain_name      = var.domain_name
  jenkins_hostname = var.jenkins_hostname
  vpc_networks = [
    module.networking_project1.vpc_self_link,
    module.networking_project2.vpc_self_link
  ]

  jenkins_lb_ip = module.load_balancer.lb_ip_address

  depends_on = [module.vpc_peering, module.load_balancer]
}

# Module: Firezone Gateway (Phase 2)
module "firezone_gateway" {
  source = "./modules/firezone-gateway"

  providers = {
    google = google.networking
  }

  project_id     = var.project_id_networking
  region         = var.region
  zone           = var.zone
  vpc_name       = module.networking_project1.vpc_name
  subnet_name    = module.networking_project1.subnet_name
  firezone_token = var.firezone_token
  machine_type   = "e2-small"

  depends_on = [module.networking_project1, module.vpc_peering]
}

# Outputs
output "project1_vpc_name" {
  description = "VPC name in Project 1"
  value       = module.networking_project1.vpc_name
}

output "project2_vpc_name" {
  description = "VPC name in Project 2"
  value       = module.networking_project2.vpc_name
}

output "jenkins_vm_private_ip" {
  description = "Jenkins VM private IP address"
  value       = module.jenkins_vm.private_ip
}

output "jenkins_lb_ip" {
  description = "Internal Load Balancer IP address"
  value       = module.load_balancer.lb_ip_address
}

output "jenkins_url" {
  description = "Jenkins access URL (will work after VPN is configured)"
  value       = "https://${var.jenkins_hostname}"
}

output "dns_zone_name" {
  description = "Private DNS zone name"
  value       = module.dns.zone_name
}

output "vpc_peering_status" {
  description = "VPC peering connection status"
  value = {
    peering_1_to_2 = module.vpc_peering.peering_1_to_2_state
    peering_2_to_1 = module.vpc_peering.peering_2_to_1_state
  }
}

output "firezone_gateway_ip" {
  description = "Firezone gateway public IP"
  value       = module.firezone_gateway.gateway_ip
}

output "next_steps" {
  description = "Next steps after Phase 1"
  value       = <<-EOT
  
  Phase 1 Deployment Complete! ✅
  
  Resources Created:
  - VPC networks in both projects
  - VPC peering between projects
  - Jenkins VM with data disk
  - Internal Load Balancer
  - Private DNS zone
  
  Next Steps:
  1. Get Firezone token from https://firezone.dev
  2. Update terraform.tfvars with your Firezone token
  3. Deploy Phase 2 (Firezone Gateway)
  4. Configure Firezone resources
  5. Access Jenkins via VPN
  
  To access Jenkins VM now (via IAP):
  gcloud compute ssh jenkins-vm --project=test-project2-485105 --zone=us-central1-a --tunnel-through-iap
  
  EOT
}
