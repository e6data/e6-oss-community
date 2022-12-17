
resource "google_vpc_access_connector" "connector" {
  count         = var.action == "destroy" ? 0 : 1
  provider      = google.destination
  name          = var.workspace_name
  network       = var.destination_network
  ip_cidr_range = var.serverless_subnet_cidr
}
data "google_cloudfunctions_function" "my-function" {
  provider = google.destination
  name     = "e6data-${var.workspace_name}-meta"
}

resource "google_cloudfunctions_function" "meta-function" {
  project               = var.destination_project
  provider              = google.destination
  name                  = data.google_cloudfunctions_function.my-function.name
  runtime               = data.google_cloudfunctions_function.my-function.runtime
  entry_point           = data.google_cloudfunctions_function.my-function.entry_point
  trigger_http          = data.google_cloudfunctions_function.my-function.trigger_http
  available_memory_mb   = data.google_cloudfunctions_function.my-function.available_memory_mb
  timeout               = data.google_cloudfunctions_function.my-function.timeout
  vpc_connector         = var.workspace_name
  source_archive_bucket = data.google_cloudfunctions_function.my-function.source_archive_bucket
  source_archive_object = data.google_cloudfunctions_function.my-function.source_archive_object
  depends_on = [
    google_vpc_access_connector.connector
  ]
}

data "google_compute_network" "source_network" {
  provider = google.source
  name     = var.source_network
}
data "google_compute_network" "destination_network" {
  provider = google.destination
  name     = var.destination_network
}
resource "google_compute_network_peering" "source_to_destination" {
  count        = var.action == "destroy" ? 0 : 1
  name         = "source-to-destination-peering-${var.workspace_name}"
  network      = data.google_compute_network.source_network.self_link
  peer_network = data.google_compute_network.destination_network.self_link
  depends_on = [
    google_vpc_access_connector.connector
  ]
}

resource "google_compute_network_peering" "destination_to_source" {
  count        = var.action == "destroy" ? 0 : 1
  name         = "destination-to-source-peering-${var.workspace_name}"
  network      = data.google_compute_network.destination_network.self_link
  peer_network = data.google_compute_network.source_network.self_link
  depends_on = [
    google_vpc_access_connector.connector
  ]
}







