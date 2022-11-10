variable "network" {
  type        = string
  description = "GCP network"
}

variable "subnetwork" {
  type        = string
  description = "GCP subnetwork"
}

variable "hive_host" {
  type        = string
  description = "Hive metastore IP"
}
variable "hive_port" {
  type        = string
  description = "Hive metastore Port"
  default = "9083"
}
variable "cluster_name" {
  type        = string
  description = "EMR Cluster Name"
}

variable "uuid" {
  type        = string
  description = "unique id"
}
variable "instance_count" {
  type = number
  description = "The number of core instances"
}

variable "region" {
  type = string
  description = "GCP region"
}

variable "enable_spot" {
  type = bool
  description = "Enable if spot required"
}