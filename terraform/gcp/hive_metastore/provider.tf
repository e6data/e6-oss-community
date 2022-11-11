provider "google" {
    project = var.project
    #access_token = "{{ gcp_access_token }}"
}

provider "google-beta" {
    project = var.project
    #access_token = "{{ gcp_access_token }}"
}