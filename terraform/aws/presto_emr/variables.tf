# variable "configurations_json" {
#   type        = string
#   description = "A JSON string for supplying list of configurations for the EMR cluster"
#   default = "./modules/presto/aws/configuration.json.tpl"
# }
variable "hive_host" {
  type        = string
  description = "Hive metastore IP"
}
variable "hive_port" {
  type        = string
  description = "Hive metastore Port"
  default     = "9083"
}
variable "cluster_name" {
  type        = string
  description = "EMR Cluster Name"
}
variable "uuid" {
  type        = string
  description = "unique id"
  default     = "112233"
}
variable "master_instance_type" {
  type        = string
  default     = "r5.2xlarge"
  description = "The instance type of the master"
}
variable "core_instance_type" {
  type        = string
  default     = "r5.8xlarge"
  description = "The instance type of the core"
}
variable "instance_count" {
  type        = string
  description = "The number of core instances"
}
variable "aws_account_id" {
  type        = string
  description = "The account ID of AWS account"
  default     = "123456789012"
}
variable "enable_spot" {
  type        = bool
  default     = false
  description = "Enable spot instances"
}
variable "bid_price" {
  type        = string
  default     = "1.75"
  description = "Bid price for each EC2 Spot instance"
}
