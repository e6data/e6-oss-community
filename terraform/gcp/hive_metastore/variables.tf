variable "region" {
  type = string
  description = "GCP Region"
}

variable "network" {
  type = string
  description = "GCP VPC"
}

variable "subnetwork" {
  description = "Self link of subnetwork"
#  default     = "{{subnetwork}}"
}
variable "instance_type" {
  type = string
  description = "machine type"
}