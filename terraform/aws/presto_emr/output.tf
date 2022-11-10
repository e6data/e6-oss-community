output "aws_presto_dns" {
  value = aws_emr_cluster.cluster.master_public_dns
}
