# 🔍 Complete Terraform Infrastructure Audit & Learning Guide

## VPN-Based Air-Gapped Jenkins Infrastructure on GCP

**Document Version:** 1.0  
**Last Updated:** February 16, 2026  
**Purpose:** Complete code walkthrough, connections, and learning path

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Directory Structure](#directory-structure)
3. [Execution Flow](#execution-flow)
4. [Root Configuration Files](#root-configuration-files)
5. [Module Deep Dive](#module-deep-dive)
6. [Resource Dependencies](#resource-dependencies)
7. [Data Flow](#data-flow)
8. [Learning Path](#learning-path)

---

## Project Overview

### What This Infrastructure Does

This Terraform project creates a **secure, air-gapped Jenkins CI/CD environment** on Google Cloud Platform with:

- **Two GCP Projects** (multi-project architecture)
- **VPN-only access** (no public internet access to Jenkins)
- **Complete network isolation** (air-gapped)
- **Internal load balancing**
- **Private DNS resolution**

### Architecture Summary

```
Project 1 (Networking)          Project 2 (Core IT)
┌─────────────────────┐        ┌─────────────────────┐
│ Firezone VPN        │        │ Jenkins VM          │
│ 20.20.20.0/16       │◄──────►│ 10.10.10.0/16       │
│ Public IP           │ Peering│ No Public IP        │
└─────────────────────┘        └─────────────────────┘
```

### Key Design Decisions

1. **Two Projects:** Separation of concerns (networking vs application)
2. **VPC Peering:** Private connectivity without internet gateway
3. **No Public IPs on Jenkins:** Complete air-gap security
4. **Internal Load Balancer:** Stable endpoint with health checks
5. **Modular Design:** Reusable, testable components

---

## Directory Structure

```
terraform/
├── main.tf                    # Root module - orchestrates everything
├── variables.tf               # Input variable definitions
├── terraform.tfvars           # Actual variable values (your config)
├── terraform.tfvars.example   # Template for others
├── .terraform.lock.hcl        # Provider version lock
├── terraform.tfstate          # Current infrastructure state
├── tfplan                     # Saved execution plan
│
└── modules/                   # Reusable components
    ├── networking/            # VPC and subnet creation
    ├── vpc-peering/           # Connect two VPCs
    ├── firezone-gateway/      # VPN gateway VM
    ├── jenkins-vm/            # Jenkins application VM
    ├── load-balancer/         # Internal LB
    └── dns/                   # Private DNS zone
```

### File Purposes

| File | Purpose | When Used |
|------|---------|-----------|
| `main.tf` | Orchestration | Every terraform command |
| `variables.tf` | Variable schema | Defines what inputs are needed |
| `terraform.tfvars` | Your values | Provides actual configuration |
| `.terraform.lock.hcl` | Version lock | Ensures consistent provider versions |
| `terraform.tfstate` | Current state | Tracks what's deployed |
| `tfplan` | Execution plan | Preview before apply |

---

## Execution Flow

### When You Run `terraform apply`

```
1. terraform init
   └─> Downloads providers (google ~5.0)
   └─> Initializes modules
   └─> Sets up backend (local or GCS)

2. terraform plan
   └─> Reads main.tf
   └─> Loads variables.tf
   └─> Applies terraform.tfvars values
   └─> Evaluates modules in dependency order
   └─> Creates execution plan

3. terraform apply
   └─> Executes plan in correct order:
       ├─> networking_project1 (VPC 1)
       ├─> networking_project2 (VPC 2)
       ├─> vpc_peering (connect VPCs)
       ├─> jenkins_vm (application)
       ├─> load_balancer (traffic routing)
       ├─> dns (name resolution)
       └─> firezone_gateway (VPN access)
```

### Dependency Chain

```
networking_project1 ──┐
                      ├──> vpc_peering ──> jenkins_vm ──> load_balancer ──> dns
networking_project2 ──┘                                                      │
                                                                             │
firezone_gateway ────────────────────────────────────────────────────────────┘
```

---

## Root Configuration Files

### 1. main.tf - The Orchestrator

**Purpose:** Ties everything together, defines providers, calls modules

**Structure:**

```hcl
terraform {
  required_version = ">= 1.5.0"  # Minimum Terraform version
  required_providers {
    google = {
      source  = "hashicorp/google"  # Official Google provider
      version = "~> 5.0"            # Version 5.x (allows 5.1, 5.2, etc.)
    }
  }
}
```

**Why this matters:**
- `required_version`: Ensures team uses compatible Terraform
- `required_providers`: Locks provider source and version
- `~> 5.0`: Allows minor updates (5.1, 5.2) but not major (6.0)

**Provider Configuration:**

```hcl
# Three providers for multi-project setup
provider "google" {
  alias   = "networking"
  project = var.project_id_networking  # test-project1-485105
  region  = var.region
}

provider "google" {
  alias   = "coreit"
  project = var.project_id_coreit      # test-project2-485105
  region  = var.region
}

provider "google" {
  project = var.project_id_networking  # Default provider
  region  = var.region
}
```

**Why three providers?**
- **networking**: For Project 1 resources (VPN gateway)
- **coreit**: For Project 2 resources (Jenkins)
- **default**: Fallback provider

**Module Calls:**

Each module call follows this pattern:
```hcl
module "module_name" {
  source = "./modules/module_name"
  
  providers = {
    google = google.alias_name  # Which project to use
  }
  
  # Input variables
  variable_name = value
  
  # Dependencies
  depends_on = [other_modules]
}
```

---

## Module Deep Dive

### Module 1: Networking

**Location:** `terraform/modules/networking/`

**Purpose:** Creates VPC network and subnet in a GCP project

**Files:**
- `main.tf` - Resource definitions
- `variables.tf` - Input parameters
- `outputs.tf` - Values to export
- `versions.tf` - Provider requirements

#### main.tf Explained

```hcl
resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false  # Manual subnet control
  project                 = var.project_id
}
```

**Line-by-line:**
1. `resource "google_compute_network" "vpc"` - Creates a VPC
2. `name = var.vpc_name` - Uses input variable for name
3. `auto_create_subnetworks = false` - We define subnets manually
4. `project = var.project_id` - Which GCP project

**Why `auto_create_subnetworks = false`?**
- Gives us control over IP ranges
- Allows custom subnet configuration
- Required for multi-region setups

```hcl
resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr      # e.g., "10.10.10.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id  # References VPC above
  project       = var.project_id
  
  private_ip_google_access = true  # Access GCP APIs without internet
}
```

**Key Concept - Resource References:**
- `google_compute_network.vpc.id` - References the VPC created above
- Terraform automatically creates dependency: VPC → Subnet
- Subnet waits for VPC to be created first

**private_ip_google_access = true:**
- Allows VMs to reach GCP services (Cloud Logging, Monitoring)
- Without needing public IPs or Cloud NAT
- Essential for air-gapped setup

#### variables.tf Explained

```hcl
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}
```

**Variable anatomy:**
- `variable "name"` - Variable identifier
- `description` - Human-readable explanation
- `type` - Data type (string, number, bool, list, map)
- `default` - Optional default value

**Variable types used:**
- `string` - Text values (project IDs, names)
- `bool` - True/false (enable_cloud_nat)
- `number` - Numeric values (disk sizes)

#### outputs.tf Explained

```hcl
output "vpc_self_link" {
  description = "VPC network self link"
  value       = google_compute_network.vpc.self_link
}
```

**Why outputs?**
- Pass values to other modules
- Display information after apply
- Use in other Terraform configurations

**self_link vs id vs name:**
- `self_link` - Full GCP resource URL (for API calls)
- `id` - Terraform resource identifier
- `name` - Human-readable name

#### How Networking Module is Called

**From main.tf:**
```hcl
module "networking_project1" {
  source = "./modules/networking"
  
  providers = {
    google = google.networking  # Use Project 1
  }
  
  project_id  = var.project_id_networking  # "test-project1-485105"
  region      = var.region                 # "us-central1"
  vpc_name    = "networkingglobal-vpc"
  vpc_cidr    = "20.20.20.0/16"
  subnet_name = "vpn-subnet"
  subnet_cidr = "20.20.20.0/24"
}
```

**What happens:**
1. Terraform loads module from `./modules/networking`
2. Uses `google.networking` provider (Project 1)
3. Passes variables to module
4. Module creates VPC and subnet
5. Returns outputs (vpc_name, vpc_self_link, etc.)

**Called twice:**
- Once for Project 1 (VPN network)
- Once for Project 2 (Jenkins network)

---

### Module 2: VPC Peering

**Location:** `terraform/modules/vpc-peering/`

**Purpose:** Connects two VPCs for private communication

**Why VPC Peering?**
- No internet gateway needed
- Private IP communication
- No bandwidth costs
- Low latency


#### VPC Peering main.tf Explained

```hcl
resource "google_compute_network_peering" "peering_1_to_2" {
  name         = "networking-to-coreit"
  network      = var.network_1_self_link  # Source VPC
  peer_network = var.network_2_self_link  # Destination VPC
  
  export_custom_routes = true  # Share custom routes
  import_custom_routes = true  # Accept custom routes
  export_subnet_routes_with_public_ip = true
  import_subnet_routes_with_public_ip = true
}
```

**Critical Concept - Bidirectional Peering:**

VPC peering requires TWO resources:
1. **peering_1_to_2**: Project 1 → Project 2
2. **peering_2_to_1**: Project 2 → Project 1

**Why bidirectional?**
- Each VPC must explicitly allow the connection
- Ensures both sides agree to peer
- Allows asymmetric routing policies

**Route Export/Import:**
- `export_custom_routes = true` - Share my routes with peer
- `import_custom_routes = true` - Accept routes from peer
- Enables traffic flow between VPCs

**depends_on:**
```hcl
depends_on = [google_compute_network_peering.peering_1_to_2]
```
- Second peering waits for first to complete
- Prevents race conditions
- Ensures proper setup order

---

### Module 3: Jenkins VM

**Location:** `terraform/modules/jenkins-vm/`

**Purpose:** Creates Jenkins application server with data persistence

**Key Components:**
1. Data disk (persistent storage)
2. VM instance (compute)
3. Firewall rules (security)

#### Data Disk Resource

```hcl
resource "google_compute_disk" "jenkins_data" {
  name    = "jenkins-data-disk"
  type    = "pd-standard"  # Standard persistent disk
  size    = var.data_disk_size  # 100 GB
  zone    = var.zone
  project = var.project_id
  
  labels = {
    environment = "production"
    application = "jenkins"
    deployment  = "airgapped"
  }
}
```

**Why separate data disk?**
- **Persistence**: Survives VM deletion
- **Disaster Recovery**: Can attach to new VM
- **Backup**: Can snapshot independently
- **Performance**: Can use different disk type

**Disk types:**
- `pd-standard` - HDD, cheaper, slower
- `pd-ssd` - SSD, faster, more expensive
- `pd-balanced` - Middle ground

#### VM Instance Resource

```hcl
resource "google_compute_instance" "jenkins" {
  name         = "jenkins-vm"
  machine_type = var.machine_type  # "e2-medium"
  zone         = var.zone
  project      = var.project_id
  
  tags = ["jenkins-server", "allow-iap-ssh"]
```

**Tags are crucial:**
- Used by firewall rules to target VMs
- `jenkins-server` - Allows VPN traffic
- `allow-iap-ssh` - Allows SSH via IAP

**Boot Disk:**
```hcl
boot_disk {
  initialize_params {
    image = "rocky-linux-cloud/rocky-linux-8"
    size  = var.boot_disk_size  # 50 GB
    type  = "pd-standard"
  }
}
```

**Image selection:**
- `rocky-linux-cloud/rocky-linux-8` - Base OS
- Could use custom image with Jenkins pre-installed
- Boot disk deleted when VM deleted (auto_delete = true)

**Attached Disk:**
```hcl
attached_disk {
  source      = google_compute_disk.jenkins_data.id
  device_name = "jenkins-data"
  mode        = "READ_WRITE"
}
```

**Resource reference:**
- `google_compute_disk.jenkins_data.id` - References data disk
- Creates dependency: Disk → VM
- Disk must exist before VM

**Network Interface:**
```hcl
network_interface {
  subnetwork = var.subnet_name
  network_ip = "10.10.10.10"  # Static private IP
  # No access_config block = No public IP
}
```

**Air-gapped configuration:**
- No `access_config` block
- No public IP assigned
- Only private IP (10.10.10.10)
- Cannot reach internet
- Internet cannot reach it

**Metadata Startup Script:**
```hcl
metadata_startup_script = <<-EOF
  #!/bin/bash
  # Runs once when VM first boots
  
  # Mount data disk
  mount /dev/sdb /var/lib/jenkins
  
  # Install Jenkins
  dnf install -y jenkins
  
  # Start Jenkins
  systemctl start jenkins
EOF
```

**Startup script flow:**
1. VM boots
2. Script runs as root
3. Mounts data disk (/dev/sdb)
4. Installs Jenkins
5. Starts Jenkins service

**Service Account:**
```hcl
service_account {
  scopes = [
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring.write"
  ]
}
```

**Scopes = Permissions:**
- `cloud-platform` - Full GCP API access
- `logging.write` - Send logs to Cloud Logging
- `monitoring.write` - Send metrics to Cloud Monitoring

**Lifecycle:**
```hcl
lifecycle {
  ignore_changes = [
    metadata_startup_script
  ]
}
```

**Why ignore_changes?**
- Startup script only runs once
- Changing it doesn't recreate VM
- Prevents unnecessary VM replacement

#### Firewall Rules

**Rule 1: IAP SSH Access**
```hcl
resource "google_compute_firewall" "jenkins_iap_ssh" {
  name    = "jenkins-iap-ssh"
  network = var.vpc_name
  
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  
  source_ranges = ["35.235.240.0/20"]  # Google IAP range
  target_tags   = ["jenkins-server"]
}
```

**What is IAP?**
- Identity-Aware Proxy
- SSH without public IP
- Uses Google's infrastructure
- Command: `gcloud compute ssh jenkins-vm --tunnel-through-iap`

**How it works:**
1. You run gcloud command
2. Request goes to Google IAP
3. IAP tunnels to VM's private IP
4. You get SSH access

**Rule 2: VPN Access**
```hcl
resource "google_compute_firewall" "jenkins_vpn_access" {
  name    = "allow-vpn-to-jenkins"
  network = var.vpc_name
  
  allow {
    protocol = "tcp"
    ports    = ["8080", "443"]  # Jenkins HTTP and HTTPS
  }
  
  source_ranges = [var.vpn_subnet_cidr]  # "20.20.20.0/24"
  target_tags   = ["jenkins-server"]
}
```

**Firewall logic:**
- Source: VPN subnet (20.20.20.0/24)
- Destination: VMs with tag "jenkins-server"
- Ports: 8080 (Jenkins), 443 (HTTPS)
- Action: ALLOW

**Rule 3: Health Checks**
```hcl
resource "google_compute_firewall" "jenkins_health_check" {
  name    = "jenkins-health-check"
  network = var.vpc_name
  
  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }
  
  source_ranges = [
    "35.191.0.0/16",    # GCP health check range 1
    "130.211.0.0/22"    # GCP health check range 2
  ]
  target_tags = ["jenkins-server"]
}
```

**Why health checks?**
- Load balancer needs to check if Jenkins is up
- Probes port 8080 every 10 seconds
- If unhealthy, stops sending traffic
- These are Google's health check IP ranges

---

### Module 4: Load Balancer

**Location:** `terraform/modules/load-balancer/`

**Purpose:** Provides stable endpoint and health monitoring

**Components:**
1. Health check
2. Instance group
3. Backend service
4. Forwarding rule


#### Load Balancer Architecture

```
User Request → Forwarding Rule (10.10.10.100:443)
                      ↓
              Backend Service
                      ↓
              Instance Group
                      ↓
              Jenkins VM (10.10.10.10:8080)
```

#### Health Check Resource

```hcl
resource "google_compute_health_check" "jenkins_health" {
  name    = "jenkins-health-check"
  
  timeout_sec         = 5   # Wait 5 seconds for response
  check_interval_sec  = 10  # Check every 10 seconds
  healthy_threshold   = 2   # 2 successes = healthy
  unhealthy_threshold = 3   # 3 failures = unhealthy
  
  http_health_check {
    port         = 8080
    request_path = "/login"  # Jenkins login page
  }
}
```

**Health check logic:**
1. Every 10 seconds, probe Jenkins
2. HTTP GET to http://10.10.10.10:8080/login
3. If response in 5 seconds → success
4. 2 consecutive successes → mark healthy
5. 3 consecutive failures → mark unhealthy

**Why /login path?**
- Always available (doesn't require auth)
- Returns 200 OK if Jenkins is up
- Lightweight check

#### Instance Group

```hcl
resource "google_compute_instance_group" "jenkins_group" {
  name      = "jenkins-instance-group"
  zone      = var.zone
  instances = [var.jenkins_instance]  # List of VM self-links
  
  named_port {
    name = "http"
    port = 8080
  }
}
```

**What is instance group?**
- Container for VM instances
- Used by load balancer to find backends
- Can contain multiple VMs (we have 1)
- Named port maps "http" → 8080

#### Backend Service

```hcl
resource "google_compute_region_backend_service" "jenkins_backend" {
  name                  = "jenkins-backend-service"
  protocol              = "TCP"
  load_balancing_scheme = "INTERNAL"  # Internal LB
  health_checks         = [google_compute_health_check.jenkins_health.id]
  
  backend {
    group          = google_compute_instance_group.jenkins_group.id
    balancing_mode = "CONNECTION"  # Balance by connection count
  }
}
```

**Backend service role:**
- Connects health check to instance group
- Defines load balancing algorithm
- Only sends traffic to healthy instances

**Balancing modes:**
- `CONNECTION` - Distribute by connection count
- `UTILIZATION` - Distribute by CPU usage
- `RATE` - Distribute by requests per second

#### Forwarding Rule

```hcl
resource "google_compute_forwarding_rule" "jenkins_lb" {
  name                  = "jenkins-lb-forwarding-rule"
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.jenkins_backend.id
  ip_protocol           = "TCP"
  ports                 = ["8080", "443"]
  network               = var.vpc_name
  subnetwork            = var.subnet_name
  ip_address            = "10.10.10.100"  # Static internal IP
}
```

**Forwarding rule = Entry point:**
- Listens on 10.10.10.100
- Accepts traffic on ports 8080 and 443
- Forwards to backend service
- This is the IP users connect to

**Why static IP?**
- DNS points to this IP
- IP doesn't change if LB recreated
- Predictable addressing

---

### Module 5: DNS

**Location:** `terraform/modules/dns/`

**Purpose:** Private DNS resolution for internal services

#### Managed Zone

```hcl
resource "google_dns_managed_zone" "private_zone" {
  name        = replace(var.domain_name, ".", "-")  # "learningmyway-space"
  dns_name    = "${var.domain_name}."               # "learningmyway.space."
  visibility  = "private"  # Only visible to specified VPCs
  
  private_visibility_config {
    networks {
      network_url = vpc_network_1_self_link
    }
    networks {
      network_url = vpc_network_2_self_link
    }
  }
}
```

**Private DNS zone:**
- Not visible on public internet
- Only accessible from specified VPCs
- Both VPCs can resolve names

**Why both VPCs?**
- VPN gateway needs to resolve jenkins.np.learningmyway.space
- Jenkins VM needs to resolve (for internal services)
- VPC peering doesn't automatically share DNS

#### DNS Record

```hcl
resource "google_dns_record_set" "jenkins_a_record" {
  name         = "${var.jenkins_hostname}."  # "jenkins.np.learningmyway.space."
  type         = "A"                         # IPv4 address
  ttl          = 300                         # Cache for 5 minutes
  managed_zone = google_dns_managed_zone.private_zone.name
  
  rrdatas = [var.jenkins_lb_ip]  # "10.10.10.100"
}
```

**A record:**
- Maps hostname to IP address
- jenkins.np.learningmyway.space → 10.10.10.100
- TTL 300 = cache for 5 minutes

**DNS resolution flow:**
1. User types: https://jenkins.np.learningmyway.space
2. VM queries private DNS zone
3. Gets response: 10.10.10.100
4. Connects to load balancer
5. Load balancer forwards to Jenkins

---

### Module 6: Firezone Gateway

**Location:** `terraform/modules/firezone-gateway/`

**Purpose:** VPN gateway for secure remote access

#### Firezone VM

```hcl
resource "google_compute_instance" "firezone_gateway" {
  name         = "firezone-gateway"
  machine_type = var.machine_type  # "e2-small"
  
  tags = ["firezone-gateway", "allow-vpn"]
  
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
    }
  }
  
  network_interface {
    subnetwork = var.subnet_name
    
    access_config {
      # Ephemeral public IP
    }
  }
```

**Key difference from Jenkins:**
- **Has public IP** (access_config block present)
- Needs public IP for VPN clients to connect
- Only VM with public IP in entire infrastructure

**Startup script:**
```hcl
metadata_startup_script = templatefile("${path.module}/scripts/firezone-install.sh", {
  firezone_token = var.firezone_token
})
```

**templatefile function:**
- Reads script from file
- Replaces variables (${firezone_token})
- Returns rendered script
- Keeps code clean and maintainable

#### Firewall Rules

**Rule 1: VPN Traffic**
```hcl
resource "google_compute_firewall" "firezone_vpn" {
  name    = "firezone-vpn-traffic"
  
  allow {
    protocol = "udp"
    ports    = ["51820"]  # WireGuard VPN
  }
  
  allow {
    protocol = "tcp"
    ports    = ["443"]    # HTTPS management
  }
  
  source_ranges = ["0.0.0.0/0"]  # Allow from anywhere
  target_tags   = ["firezone-gateway"]
}
```

**Why 0.0.0.0/0?**
- VPN clients connect from anywhere
- Could be home, office, mobile
- Can't predict source IPs
- Firezone handles authentication

**Rule 2: Egress to Jenkins**
```hcl
resource "google_compute_firewall" "firezone_egress" {
  name      = "firezone-to-jenkins-egress"
  direction = "EGRESS"  # Outbound traffic
  
  allow {
    protocol = "tcp"
  }
  
  allow {
    protocol = "udp"
  }
  
  destination_ranges = ["10.10.10.0/24"]  # Jenkins subnet
  target_tags        = ["firezone-gateway"]
}
```

**Egress rule:**
- Allows Firezone to reach Jenkins subnet
- Required for VPN traffic forwarding
- Without this, VPN clients can't reach Jenkins

---

## Resource Dependencies

### Dependency Graph

```
terraform init
     ↓
variables.tf (load variable definitions)
     ↓
terraform.tfvars (load actual values)
     ↓
main.tf (orchestration)
     ↓
┌────────────────────────────────────────┐
│  Phase 1: Networking                   │
├────────────────────────────────────────┤
│  networking_project1 (VPC 1)           │
│  networking_project2 (VPC 2)           │
└────────────────────────────────────────┘
     ↓
┌────────────────────────────────────────┐
│  Phase 2: VPC Peering                  │
├────────────────────────────────────────┤
│  vpc_peering (connect VPCs)            │
│  depends_on: both networking modules   │
└────────────────────────────────────────┘
     ↓
┌────────────────────────────────────────┐
│  Phase 3: Compute                      │
├────────────────────────────────────────┤
│  jenkins_vm (data disk + VM)           │
│  depends_on: networking_project2       │
└────────────────────────────────────────┘
     ↓
┌────────────────────────────────────────┐
│  Phase 4: Load Balancer                │
├────────────────────────────────────────┤
│  load_balancer (health check + LB)     │
│  depends_on: jenkins_vm                │
└────────────────────────────────────────┘
     ↓
┌────────────────────────────────────────┐
│  Phase 5: DNS                          │
├────────────────────────────────────────┤
│  dns (private zone + A record)         │
│  depends_on: vpc_peering, load_balancer│
└────────────────────────────────────────┘
     ↓
┌────────────────────────────────────────┐
│  Phase 6: VPN Gateway                  │
├────────────────────────────────────────┤
│  firezone_gateway (VPN VM)             │
│  depends_on: networking_project1       │
└────────────────────────────────────────┘
```

### Implicit vs Explicit Dependencies

**Implicit (automatic):**
```hcl
resource "google_compute_instance" "vm" {
  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
  }
}
```
- Terraform sees reference to subnet
- Automatically creates dependency
- Subnet created before VM

**Explicit (manual):**
```hcl
module "dns" {
  # ...
  depends_on = [module.vpc_peering, module.load_balancer]
}
```
- Manually specify dependencies
- Used when implicit detection fails
- Ensures correct order


---

## Data Flow

### User Request Flow

```
1. User connects to Firezone VPN
   ├─> WireGuard client on laptop
   ├─> Connects to Firezone Gateway public IP
   └─> Authenticated by Firezone

2. User opens browser: https://jenkins.np.learningmyway.space
   ├─> DNS query sent
   ├─> Private DNS zone responds: 10.10.10.100
   └─> Browser connects to 10.10.10.100:443

3. Traffic flows through VPN tunnel
   ├─> Encrypted by WireGuard
   ├─> Sent to Firezone Gateway (20.20.20.x)
   ├─> Firezone forwards to Jenkins subnet (10.10.10.0/24)
   └─> VPC peering routes traffic

4. Load Balancer receives request
   ├─> Forwarding rule on 10.10.10.100:443
   ├─> Checks backend health
   ├─> Forwards to healthy instance
   └─> Sends to Jenkins VM (10.10.10.10:8080)

5. Jenkins processes request
   ├─> Nginx terminates TLS (443 → 8080)
   ├─> Jenkins handles HTTP request
   ├─> Generates response
   └─> Returns through same path
```

### Terraform State Flow

```
terraform apply
     ↓
1. Read terraform.tfstate
   ├─> Current infrastructure state
   ├─> Resource IDs and attributes
   └─> Dependency information

2. Read configuration files
   ├─> main.tf (desired state)
   ├─> variables.tf (parameters)
   └─> terraform.tfvars (values)

3. Calculate diff
   ├─> Compare current vs desired
   ├─> Determine changes needed
   └─> Create execution plan

4. Execute plan
   ├─> Create new resources
   ├─> Update existing resources
   ├─> Delete removed resources
   └─> Respect dependencies

5. Update state file
   ├─> Record new resource IDs
   ├─> Store attributes
   └─> Save for next run
```

---

## Learning Path

### Level 1: Beginner (Understanding Basics)

**Start here if you're new to Terraform**

1. **Read terraform/variables.tf**
   - Understand variable types
   - See how defaults work
   - Learn sensitive variables

2. **Read terraform/terraform.tfvars**
   - See actual values
   - Understand project IDs
   - Learn configuration format

3. **Read terraform/main.tf (top section)**
   - Understand terraform block
   - Learn provider configuration
   - See version constraints

4. **Read modules/networking/main.tf**
   - Simple VPC creation
   - Subnet configuration
   - Resource references

**Key Concepts to Master:**
- Variables (input parameters)
- Resources (infrastructure components)
- Providers (cloud platform APIs)
- Outputs (return values)

### Level 2: Intermediate (Module Architecture)

**Once you understand basics**

1. **Study module structure**
   - main.tf (resources)
   - variables.tf (inputs)
   - outputs.tf (exports)
   - versions.tf (requirements)

2. **Analyze module calls in main.tf**
   - How modules are invoked
   - Variable passing
   - Provider assignment
   - Dependency management

3. **Trace data flow**
   - networking → vpc_peering
   - jenkins_vm → load_balancer
   - load_balancer → dns

4. **Understand resource references**
   - `module.networking_project1.vpc_name`
   - `google_compute_disk.jenkins_data.id`
   - `var.jenkins_instance`

**Key Concepts to Master:**
- Module composition
- Resource dependencies
- Data passing between modules
- Provider aliases

### Level 3: Advanced (Multi-Project Architecture)

**For experienced users**

1. **Multi-project setup**
   - Why two projects?
   - Provider aliases
   - Cross-project networking

2. **VPC peering mechanics**
   - Bidirectional peering
   - Route export/import
   - Firewall implications

3. **Security architecture**
   - No public IPs (air-gap)
   - IAP for SSH
   - Firewall rules
   - VPN-only access

4. **State management**
   - Local vs remote state
   - State locking
   - Team collaboration

**Key Concepts to Master:**
- Multi-project patterns
- Network security
- State management
- Disaster recovery

### Level 4: Expert (Production Readiness)

**Production deployment considerations**

1. **State backend**
   - GCS backend configuration
   - State locking
   - Backup strategies

2. **CI/CD integration**
   - Automated terraform apply
   - Plan review process
   - Approval workflows

3. **Monitoring and alerting**
   - Resource health
   - Cost tracking
   - Change notifications

4. **Disaster recovery**
   - Backup procedures
   - Recovery testing
   - RTO/RPO objectives

**Key Concepts to Master:**
- Production best practices
- Team workflows
- Automation
- Operational excellence

---

## Best Practices Demonstrated

### 1. Modular Design

**Why:**
- Reusable components
- Easier testing
- Clear separation of concerns
- Maintainable code

**Example:**
```hcl
# Bad: Everything in main.tf
resource "google_compute_network" "vpc1" { }
resource "google_compute_subnetwork" "subnet1" { }
resource "google_compute_network" "vpc2" { }
resource "google_compute_subnetwork" "subnet2" { }

# Good: Reusable module
module "networking_project1" {
  source = "./modules/networking"
  # ...
}
module "networking_project2" {
  source = "./modules/networking"
  # ...
}
```

### 2. Variable Management

**Why:**
- Configuration flexibility
- Environment-specific values
- Sensitive data protection

**Example:**
```hcl
# variables.tf - Define schema
variable "firezone_token" {
  type      = string
  sensitive = true  # Hide in logs
}

# terraform.tfvars - Provide value
firezone_token = "actual-token-here"
```

### 3. Resource Naming

**Why:**
- Easy identification
- Consistent patterns
- Clear purpose

**Pattern:**
```
<service>-<component>-<descriptor>
jenkins-lb-forwarding-rule
jenkins-health-check
jenkins-instance-group
```

### 4. Tagging Strategy

**Why:**
- Firewall targeting
- Cost allocation
- Resource organization

**Example:**
```hcl
tags = ["jenkins-server", "allow-iap-ssh"]

labels = {
  environment = "production"
  application = "jenkins"
  deployment  = "airgapped"
}
```

### 5. Dependency Management

**Why:**
- Correct creation order
- Prevent race conditions
- Reliable deployments

**Example:**
```hcl
module "dns" {
  # ...
  depends_on = [
    module.vpc_peering,
    module.load_balancer
  ]
}
```

### 6. Output Values

**Why:**
- Share information
- Display important data
- Use in other configs

**Example:**
```hcl
output "jenkins_url" {
  description = "Jenkins access URL"
  value       = "https://${var.jenkins_hostname}"
}
```

---

## Common Patterns Explained

### Pattern 1: Provider Aliases

**Problem:** Need to manage resources in multiple projects

**Solution:**
```hcl
provider "google" {
  alias   = "networking"
  project = "project-1"
}

provider "google" {
  alias   = "coreit"
  project = "project-2"
}

module "resource_in_project1" {
  providers = {
    google = google.networking
  }
}
```

### Pattern 2: Dynamic Blocks

**Problem:** Conditional resource configuration

**Solution:**
```hcl
dynamic "private_visibility_config" {
  for_each = length(var.vpc_networks) > 0 ? [1] : []
  content {
    # Configuration here
  }
}
```

**Explanation:**
- `for_each` - Loop over list
- `[1]` - Create one block
- `[]` - Create zero blocks
- Conditional: only if vpc_networks not empty

### Pattern 3: Resource References

**Problem:** Use output from one resource in another

**Solution:**
```hcl
# Create resource
resource "google_compute_disk" "data" {
  name = "my-disk"
}

# Reference it
resource "google_compute_instance" "vm" {
  attached_disk {
    source = google_compute_disk.data.id
  }
}
```

**Attributes available:**
- `.id` - Resource ID
- `.self_link` - Full GCP URL
- `.name` - Resource name
- Custom attributes (varies by resource)

### Pattern 4: Templatefile

**Problem:** Need to inject variables into scripts

**Solution:**
```hcl
metadata_startup_script = templatefile("${path.module}/script.sh", {
  token = var.firezone_token
  region = var.region
})
```

**In script.sh:**
```bash
#!/bin/bash
TOKEN="${token}"
REGION="${region}"
```

---

## Troubleshooting Guide

### Issue: "Resource already exists"

**Cause:** Resource created outside Terraform

**Solution:**
```bash
# Import existing resource
terraform import google_compute_network.vpc projects/PROJECT_ID/global/networks/VPC_NAME
```

### Issue: "Cycle error"

**Cause:** Circular dependency

**Solution:**
- Review depends_on blocks
- Check resource references
- Break circular dependencies

### Issue: "Provider configuration not present"

**Cause:** Module needs provider but not specified

**Solution:**
```hcl
module "my_module" {
  providers = {
    google = google.networking
  }
}
```

### Issue: "State lock"

**Cause:** Another terraform process running

**Solution:**
```bash
# Force unlock (use carefully!)
terraform force-unlock LOCK_ID
```

---

## Quick Reference

### Common Commands

```bash
# Initialize
terraform init

# Validate syntax
terraform validate

# Format code
terraform fmt

# Plan changes
terraform plan

# Apply changes
terraform apply

# Destroy resources
terraform destroy

# Show current state
terraform show

# List resources
terraform state list

# Target specific resource
terraform apply -target=module.jenkins_vm
```

### File Structure

```
terraform/
├── main.tf           # Root module
├── variables.tf      # Variable definitions
├── terraform.tfvars  # Variable values
└── modules/          # Reusable modules
    └── module_name/
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── versions.tf
```

### Resource Naming Convention

```
<resource_type>.<resource_name>.<attribute>

google_compute_network.vpc.id
google_compute_instance.jenkins.self_link
module.networking_project1.vpc_name
```

---

## Summary

This Terraform project demonstrates:

1. **Multi-project architecture** - Separation of networking and application
2. **Modular design** - Reusable, testable components
3. **Security-first** - Air-gapped, VPN-only access
4. **Production-ready** - Health checks, load balancing, DNS
5. **Best practices** - Variables, outputs, dependencies

**Total Resources Created:** 20
- 2 VPCs
- 2 Subnets
- 2 VMs (Firezone + Jenkins)
- 1 Data disk
- 1 Load balancer (4 components)
- 1 DNS zone + record
- 2 VPC peering connections
- 5 Firewall rules

**Estimated Cost:** ~$91/month when running

---

**END OF AUDIT**

*For questions or clarifications, refer to individual module documentation or Terraform official docs.*
