variable "source_vpc" {
  type       = string
  descrition = "the VPC having hive configured"
}
variable "destination_vpc" {
  type        = string
  description = "the VPC having e6 engine configured"
}
variable "source_project" {
  type        = string
  description = "the project id having source VPC"
}
variable "destination_project" {
  type        = string
  description = "the project id having destination VPC"
}
