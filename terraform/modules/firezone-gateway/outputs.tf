output "gateway_name" {
  description = "Firezone gateway instance name"
  value       = google_compute_instance.firezone_gateway.name
}

output "gateway_ip" {
  description = "Firezone gateway public IP"
  value       = google_compute_instance.firezone_gateway.network_interface[0].access_config[0].nat_ip
}

output "gateway_private_ip" {
  description = "Firezone gateway private IP"
  value       = google_compute_instance.firezone_gateway.network_interface[0].network_ip
}
