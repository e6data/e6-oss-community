data "aws_vpc" "source" {
  id = var.source_vpc
}

data "aws_vpc" "destination" {
  id = var.destination_vpc
}
data "aws_route_table" "pvt" {
  vpc_id = var.destination_vpc
  filter {
    name   = "tag:aws:cloudformation:logical-id"
    values = ["e6pvtRouteTable"]
  }
}
data "aws_route_table" "pub" {
  vpc_id = var.destination_vpc
  filter {
    name   = "tag:aws:cloudformation:logical-id"
    values = ["e6pubRouteTable"]
  }
}

resource "aws_vpc_peering_connection" "peer" {
  vpc_id      = data.aws_vpc.source.id
  peer_vpc_id = data.aws_vpc.destination.id
  auto_accept = true
}

resource "aws_vpc_peering_connection_options" "peer" {
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_route" "source" {
  route_table_id            = "rtb-08fe04cd7a905a9bd"
  destination_cidr_block    = data.aws_vpc.destination.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}
resource "aws_route" "destination-pvt" {
  route_table_id            = data.aws_route_table.pvt.id
  destination_cidr_block    = data.aws_vpc.source.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}
resource "aws_route" "destination-pub" {
  route_table_id            = data.aws_route_table.pub.id
  destination_cidr_block    = data.aws_vpc.source.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

