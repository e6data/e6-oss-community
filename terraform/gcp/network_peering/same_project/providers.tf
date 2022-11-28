provider "google" {
  project = var.project
  #access_token = "{{ gcp_access_token }}"
  region = "us-central1"
}
