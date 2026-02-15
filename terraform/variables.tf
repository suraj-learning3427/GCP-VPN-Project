# Global Variables for VPN-Jenkins Infrastructure

variable "project_id_networking" {
  description = "GCP Project ID for networking (Project 1)"
  type        = string
  default     = "test-project1-485105"
}

variable "project_id_coreit" {
  description = "GCP Project ID for core IT infrastructure (Project 2)"
  type        = string
  default     = "test-project2-485105"
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone for resources"
  type        = string
  default     = "us-central1-a"
}

variable "domain_name" {
  description = "Domain name for Jenkins"
  type        = string
  default     = "learningmyway.space"
}

variable "jenkins_hostname" {
  description = "Jenkins hostname"
  type        = string
  default     = "jenkins.np.learningmyway.space"
}

variable "firezone_token" {
  description = "Firezone gateway token"
  type        = string
  sensitive   = true
}

variable "jenkins_vm_machine_type" {
  description = "Machine type for Jenkins VM"
  type        = string
  default     = "e2-medium"
}

variable "jenkins_boot_disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 50
}

variable "jenkins_data_disk_size" {
  description = "Data disk size in GB"
  type        = number
  default     = 100
}
