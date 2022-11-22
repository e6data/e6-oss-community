variable "source_vpc" {
  type        = string
  description = "the VPC having hive configured"
}
variable "destination_vpc" {
  type        = string
  description = "the VPC having engine configured"
}
variable "source_region" {
  type        = string
  description = "the region with source VPC"
}
variable "destination_region" {
  type        = string
  description = "the region with destination VPC"
}
variable "route_table_id" {
  type        = string
  description = "The route table associated with subnet in which the hive metastore is present"
}
