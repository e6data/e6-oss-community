data "google_compute_network" "source_network" {
  provider = google.source
  name     = var.source_network
}
data "google_compute_network" "destination_network" {
  provider = google.destination
  name     = var.destination_network
}
resource "google_compute_network_peering" "source_to_destination" {
  name         = "source-to-destination-peering"
  network      = data.google_compute_network.source_network.self_link
  peer_network = data.google_compute_network.destination_network.self_link
}

resource "google_compute_network_peering" "destination_to_source" {
  name         = "destination-to-source-peering"
  network      = data.google_compute_network.destination_network.self_link
  peer_network = data.google_compute_network.source_network.self_link
}
