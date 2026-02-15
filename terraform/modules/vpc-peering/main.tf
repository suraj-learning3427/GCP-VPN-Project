# VPC Peering Module

# Peering from Network 1 to Network 2
resource "google_compute_network_peering" "peering_1_to_2" {
  name         = "networking-to-coreit"
  network      = var.network_1_self_link
  peer_network = var.network_2_self_link

  export_custom_routes                = true
  import_custom_routes                = true
  export_subnet_routes_with_public_ip = true
  import_subnet_routes_with_public_ip = true
}

# Peering from Network 2 to Network 1
resource "google_compute_network_peering" "peering_2_to_1" {
  name         = "coreit-to-networking"
  network      = var.network_2_self_link
  peer_network = var.network_1_self_link

  export_custom_routes                = true
  import_custom_routes                = true
  export_subnet_routes_with_public_ip = true
  import_subnet_routes_with_public_ip = true

  depends_on = [google_compute_network_peering.peering_1_to_2]
}
