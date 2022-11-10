data "google_compute_subnetwork" "metastore_subnetwork" {
  name   = var.subnetwork
  region = var.region
}

data "google_compute_network" "metastore_network" {
  name = var.network
}

data "google_compute_zones" "zones" {
  region    = var.region
}