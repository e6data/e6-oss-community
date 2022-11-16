data "aws_vpc" "source" {
  id = var.source_vpc
}

data "aws_vpc" "destination" {
  id = var.destination_vpc
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
  route_table_id            = data.aws_vpc.source.main_route_table_id
  destination_cidr_block    = data.aws_vpc.destination.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}
resource "aws_route" "destination" {
  route_table_id            = data.aws_vpc.destination.main_route_table_id
  destination_cidr_block    = data.aws_vpc.source.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

