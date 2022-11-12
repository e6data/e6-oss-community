data "google_compute_subnetwork" "metastore_subnetwork" {
  name   = var.subnetwork
  region = var.region
}

data "google_compute_network" "metastore_network" {
  name = var.network
}

data "google_compute_zones" "zones" {
  region = var.region
}

/// This resource is needed to access dataproc via cli

# resource "google_compute_firewall" "metastore_firewall" {
#   name          = "hive-metastore-firewall"
#   network       = data.google_compute_network.metastore_network.self_link
#   source_tags   = ["metastore"]
#   source_ranges = ["0.0.0.0/0"]
#   target_tags   = ["metastore"]
#   allow {
#     protocol = "TCP"
#     ports    = [var.metastore_port]
#   }
# }
