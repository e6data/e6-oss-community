provider "google" {
  project = var.project
  #access_token = "{{ gcp_access_token }}"
  region = var.region
}
