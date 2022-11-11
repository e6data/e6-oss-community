
resource "aws_emr_cluster" "cluster" {
  name                = "${var.emr_name}-${var.uuid}"
  release_label       = "emr-6.8.0"
  applications        = ["Presto"]
  configurations_json = templatefile("${path.module}/configuration.json.tpl", { hive_host = var.hive_host, hive_port = var.hive_port })

  termination_protection            = false
  keep_job_flow_alive_when_no_steps = true

  master_instance_group {
    instance_type = var.master_instance_type

    ebs_config {
      size                 = "100"
      type                 = "gp2"
      volumes_per_instance = 1
    }
  }

  core_instance_group {
    instance_type  = var.core_instance_type
    instance_count = tonumber(var.instance_count)

    ebs_config {
      size                 = "400"
      type                 = "gp2"
      volumes_per_instance = 1
    }

    bid_price = var.enable_spot == true ? var.bid_price : null
  }

  ebs_root_volume_size = 100

  tags = {
    Name = "emr-presto-${var.uuid}"
  }

  service_role = "arn:aws:iam::${var.aws_account_id}:role/EMR_DefaultRole"

  ec2_attributes {
    #   subnet_id                         = aws_subnet.main.id
    #   emr_managed_master_security_group = aws_security_group.sg.id
    #   emr_managed_slave_security_group  = aws_security_group.sg.id
    instance_profile = "arn:aws:iam::${var.aws_account_id}:instance-profile/EMR_EC2_DefaultRole"
    #    key_name = "dev"
  }
}
