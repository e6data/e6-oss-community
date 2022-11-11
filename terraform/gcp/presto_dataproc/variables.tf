variable "network" {
  type        = string
  description = "GCP network"
}

variable "subnetwork" {
  type        = string
  description = "GCP subnetwork"
}
variable "master_instance_type" {
  type        = string
  default     = "c2-standard-8"
  description = "master instance type"
}
variable "worker_instance_type" {
  type        = string
  default     = "c2-standard-30"
  description = "worker instance type"
}
variable "hive_host" {
  type        = string
  description = "Hive metastore IP"
}
variable "hive_port" {
  type        = string
  description = "Hive metastore Port"
  default     = "9083"
}
variable "dataproc_port" {
  type        = string
  description = "Hive metastore Port"
  default     = "8060"
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
  type        = number
  description = "The number of core instances"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "enable_spot" {
  type        = bool
  description = "Enable if spot required"
}
