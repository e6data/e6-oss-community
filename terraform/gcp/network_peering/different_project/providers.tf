provider "google" {
  alias   = "source"
  project = "{{ source project id }}"
  #access_token = "{{ gcp_access_token }}"
}
provider "google" {
  alias   = "destination"
  project = "{{ destination project id }}"
  #access_token = "{{ gcp_access_token }}"
}
