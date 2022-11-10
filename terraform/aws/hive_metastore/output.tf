output "metastore_ip" {
  value =  aws_instance.metastore_instance.public_dns
}

