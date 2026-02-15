variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "vpc_name" {
  description = "VPC network name"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR range"
  type        = string
}

variable "subnet_name" {
  description = "Subnet name"
  type        = string
}

variable "subnet_cidr" {
  description = "Subnet CIDR range"
  type        = string
}

variable "enable_cloud_nat" {
  description = "Enable Cloud NAT for internet access (temporary for Jenkins installation)"
  type        = bool
  default     = false
}
