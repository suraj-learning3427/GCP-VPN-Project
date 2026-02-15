# Internal Load Balancer Module

# Instance group for Jenkins
resource "google_compute_instance_group" "jenkins_group" {
  name      = "jenkins-instance-group"
  zone      = var.zone
  project   = var.project_id
  instances = [var.jenkins_instance]

  named_port {
    name = "http"
    port = 8080
  }
}

# Health check
resource "google_compute_health_check" "jenkins_health" {
  name    = "jenkins-health-check"
  project = var.project_id

  timeout_sec         = 5
  check_interval_sec  = 10
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = 8080
    request_path = "/login"
  }
}

# Backend service
resource "google_compute_region_backend_service" "jenkins_backend" {
  name                  = "jenkins-backend-service"
  region                = var.region
  project               = var.project_id
  protocol              = "TCP"
  load_balancing_scheme = "INTERNAL"
  health_checks         = [google_compute_health_check.jenkins_health.id]
  timeout_sec           = 30

  backend {
    group          = google_compute_instance_group.jenkins_group.id
    balancing_mode = "CONNECTION"
  }
}

# Forwarding rule (Internal LB)
resource "google_compute_forwarding_rule" "jenkins_lb" {
  name                  = "jenkins-lb-forwarding-rule"
  region                = var.region
  project               = var.project_id
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.jenkins_backend.id
  ip_protocol           = "TCP"
  ports                 = ["8080", "443"]
  network               = var.vpc_name
  subnetwork            = var.subnet_name
  ip_address            = "10.10.10.100"
}
