variable "source_network" {
  type        = string
  description = "the network having hive configured"
}
variable "destination_network" {
  type        = string
  description = "the network having e6 engine configured"
}
variable "source_project" {
  type        = string
  description = "the project id having source network"
}
variable "destination_project" {
  type        = string
  description = "the project id having destination network"
}
