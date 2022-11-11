variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "instance_type" {
  type        = string
  description = "instance type"
  default     = "t3.medium"
}

variable "instance_profile_arn" {
  type    = string
  default = "arn:aws:iam::123456789012:instance-profile/role-name"
}
variable "metastore_port" {
  type    = number
  default = 9083
}
variable "region" {
  type    = string
  default = "us-east-1"
}
