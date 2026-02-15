output "peering_1_to_2_name" {
  description = "Name of peering from network 1 to network 2"
  value       = google_compute_network_peering.peering_1_to_2.name
}

output "peering_1_to_2_state" {
  description = "State of peering from network 1 to network 2"
  value       = google_compute_network_peering.peering_1_to_2.state
}

output "peering_2_to_1_name" {
  description = "Name of peering from network 2 to network 1"
  value       = google_compute_network_peering.peering_2_to_1.name
}

output "peering_2_to_1_state" {
  description = "State of peering from network 2 to network 1"
  value       = google_compute_network_peering.peering_2_to_1.state
}
