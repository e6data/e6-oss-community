locals  {
  public_subnets = [for subnet in data.aws_subnet.public : subnet.id]
}

data "aws_ec2_instance_type_offerings" "instance_azs" {
  filter {
    name   = "instance-type"
    values = [var.instance_type]
  }

  location_type = "availability-zone"
}

data "aws_vpc" "selected_vpc" {
  id = var.vpc_id
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "availability-zone"
    values = data.aws_ec2_instance_type_offerings.instance_azs.locations
  }
}

data "aws_subnet" "public" {
  for_each = toset(data.aws_subnets.public.ids)
  id       = each.value
}

resource "random_string" "random" {
  length           = 5
  special          = false
}
