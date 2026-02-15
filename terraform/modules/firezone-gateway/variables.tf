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

variable "firezone_token" {
  description = "Firezone gateway token"
  type        = string
  sensitive   = true
}

variable "machine_type" {
  description = "Machine type for Firezone gateway"
  type        = string
  default     = "e2-small"
}
