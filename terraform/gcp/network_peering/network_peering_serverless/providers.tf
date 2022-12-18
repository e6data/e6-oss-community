provider "google" {
  alias   = "source"
  project = var.source_project
  region  = var.source_region
  #access_token = "{{ gcp_access_token }}"
}
provider "google" {
  alias   = "destination"
  project = var.destination_project
  region  = var.destination_region
  #access_token = "{{ gcp_access_token }}"
}
