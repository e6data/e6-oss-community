variable "region" {
  type        = string
  description = "GCP Region"
}
variable "project" {
  type        = string
  description = "GCP Project ID"
}
variable "network" {
  type        = string
  description = "GCP VPC"
}

variable "subnetwork" {
  description = "Self link of subnetwork"
  #  default     = "{{subnetwork}}"
}
variable "instance_type" {
  type        = string
  description = "machine type"
}
variable "metastore_port" {
  type    = string
  default = "9083"
}
