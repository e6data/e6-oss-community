data "google_compute_network" "source_vpc" {
  project = var.project
  name    = var.source_vpc
}
data "google_compute_network" "destination_vpc" {
  project = var.project
  name    = var.destination_vpc
}
resource "google_compute_network_peering" "source_to_destination" {
  name         = "source_to_destination"
  network      = data.google_compute_network.source_vpc.self_link
  peer_network = data.google_compute_network.destination_vpc.self_link
}

resource "google_compute_network_peering" "destination_to_source" {
  name         = "destination_to_source"
  network      = data.google_compute_network.destination_vpc.self_link
  peer_network = data.google_compute_network.source_vpc.self_link

}
