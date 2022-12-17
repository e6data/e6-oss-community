variable "source_network" {
  type        = string
  description = "the network having hive configured"
}
variable "destination_network" {
  type        = string
  description = "the network having engine configured"
}
variable "source_project" {
  type        = string
  description = "the project id having source network"
}
variable "destination_project" {
  type        = string
  description = "the project id having destination network"
}
variable "serverless_subnet_cidr" {
  type        = string
  description = "cidr range for the serverless subnet"
}

variable "source_region" {
  type        = string
  description = "GCP region"
}
variable "destination_region" {
  type        = string
  description = "GCP region"
}

variable "action" {
  type        = string
  description = "create/destroy"
}
variable "workspace_name" {
  type        = string
  description = "The name of the meta function"
}
