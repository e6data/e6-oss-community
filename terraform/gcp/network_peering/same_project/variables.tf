variable "source_network" {
  type        = string
  description = "the network having hive configured"
}
variable "destination_network" {
  type        = string
  description = "the network having e6 engine configured"
}
variable "project" {
  type        = string
  description = "the project id having source and destination networks"
}
