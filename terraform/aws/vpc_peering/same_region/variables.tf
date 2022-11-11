variable "source_vpc" {
  type        = string
  description = "the VPC having hive configured"
}
variable "destination_vpc" {
  type        = string
  description = "the VPC having engine configured"
}
variable "region" {
  type        = string
  description = "the region with VPC"
}
