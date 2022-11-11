output "gcp_presto_dns" {
  value = data.google_compute_instance.master_info.network_interface[0].access_config[0].nat_ip
}
