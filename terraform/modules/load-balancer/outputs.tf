output "lb_ip_address" {
  description = "Load balancer IP address"
  value       = google_compute_forwarding_rule.jenkins_lb.ip_address
}

output "backend_service_name" {
  description = "Backend service name"
  value       = google_compute_region_backend_service.jenkins_backend.name
}

output "health_check_name" {
  description = "Health check name"
  value       = google_compute_health_check.jenkins_health.name
}
