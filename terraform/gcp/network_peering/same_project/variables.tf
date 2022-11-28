variable "source_network" {
  type        = string
  description = "the network having hive configured"
}
variable "destination_network" {
  type        = string
  description = "the network having engine configured"
}
variable "project" {
  type        = string
  description = "the project id having source and destination networks"
}
variable "workspace_name" {
  type        = string
  description = "The name of the meta function"
}
variable "action" {
  type        = string
  description = "create/destroy"
}
variable "serverless_subnet_cidr" {
  type        = string
  description = "cidr range for the serverless subnet"
}
