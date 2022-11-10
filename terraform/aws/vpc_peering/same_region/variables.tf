variable "source_vpc" {
  type       = string
  descrition = "the VPC having hive configured"
}
variable "destination_vpc" {
  type        = string
  description = "the VPC having e6 engine configured"
}
variable "region" {
  type        = string
  description = "the region with VPC"
}
