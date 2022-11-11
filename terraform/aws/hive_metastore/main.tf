data "aws_ami" "amazon-linux-2" {
  most_recent = true


  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }


  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_security_group" "allow_firewall" {
  vpc_id = var.vpc_id
  name   = "metastore-firewall"
  ingress {
    from_port   = var.metastore_port
    to_port     = var.metastore_port
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected_vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    ignore_changes = [ingress]
  }
}

resource "aws_instance" "metastore_instance" {
  ami                         = data.aws_ami.amazon-linux-2.id
  instance_type               = var.instance_type
  iam_instance_profile        = split("/", var.instance_profile_arn)[1]
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.allow_firewall.id]
  subnet_id                   = tostring(local.public_subnets[0])
  root_block_device {
    volume_size           = "100"
    volume_type           = "gp2"
    delete_on_termination = true
  }
  user_data = file("bootstrap_script.sh")

}
