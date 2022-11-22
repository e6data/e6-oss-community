data "aws_vpc" "source" {
  id = var.source_vpc
}

data "aws_vpc" "destination" {
  id = var.destination_vpc
}
data "aws_route_tables" "source" {
  vpc_id = var.source_vpc
}
data "aws_route_tables" "destination" {
  vpc_id = var.destination_vpc
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
  count                     = length(data.aws_route_tables.source.ids)
  route_table_id            = tolist(data.aws_route_tables.source.ids)[count.index]
  destination_cidr_block    = data.aws_vpc.destination.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}
resource "aws_route" "destination" {
  count                     = length(data.aws_route_tables.destination.ids)
  route_table_id            = tolist(data.aws_route_tables.destination.ids)[count.index]
  destination_cidr_block    = data.aws_vpc.source.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}
