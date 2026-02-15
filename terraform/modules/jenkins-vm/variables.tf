variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "zone" {
  description = "GCP zone"
  type        = string
}

variable "vpc_name" {
  description = "VPC network name"
  type        = string
}

variable "subnet_name" {
  description = "Subnet name"
  type        = string
}

variable "machine_type" {
  description = "Machine type for Jenkins VM"
  type        = string
  default     = "e2-medium"
}

variable "boot_disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 50
}

variable "data_disk_size" {
  description = "Data disk size in GB"
  type        = number
  default     = 100
}

variable "vpn_subnet_cidr" {
  description = "VPN subnet CIDR for firewall rules"
  type        = string
}
