data "google_compute_subnetwork" "subnetwork_cidr" {
  name = var.subnetwork
  region = var.region
}