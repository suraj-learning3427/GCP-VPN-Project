# Private DNS Module

resource "google_dns_managed_zone" "private_zone" {
  name        = replace(var.domain_name, ".", "-")
  dns_name    = "${var.domain_name}."
  description = "Private DNS zone for Jenkins and internal services"
  project     = var.project_id

  visibility = "private"

  dynamic "private_visibility_config" {
    for_each = length(var.vpc_networks) > 0 ? [1] : []
    content {
      dynamic "networks" {
        for_each = var.vpc_networks
        content {
          network_url = networks.value
        }
      }
    }
  }
}

resource "google_dns_record_set" "jenkins_a_record" {
  name         = "${var.jenkins_hostname}."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.private_zone.name
  project      = var.project_id

  rrdatas = [var.jenkins_lb_ip]
}
