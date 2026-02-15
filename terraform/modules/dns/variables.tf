variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the private DNS zone"
  type        = string
}

variable "jenkins_hostname" {
  description = "Jenkins hostname"
  type        = string
}

variable "vpc_networks" {
  description = "List of VPC network self links to associate with the DNS zone"
  type        = list(string)
  default     = []
}

variable "jenkins_lb_ip" {
  description = "Jenkins load balancer IP address"
  type        = string
}
