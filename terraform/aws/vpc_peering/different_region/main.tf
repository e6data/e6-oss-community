data "aws_caller_identity" "current" {
  provider = aws.destination
}

data "aws_vpc" "source" {
  provider = aws.source
  id       = var.source_vpc
}

data "aws_vpc" "destination" {
  provider = aws.destination
  id       = var.destination_vpc
}
data "aws_route_tables" "source" {
  provider = aws.source
  vpc_id   = var.source_vpc
}

data "aws_route_tables" "destination" {
  provider = aws.destination
  vpc_id   = var.destination_vpc

}

# Requester's side of the connection.
resource "aws_vpc_peering_connection" "peer" {
  provider      = aws.source
  vpc_id        = var.source_vpc
  peer_vpc_id   = var.destination_vpc
  peer_owner_id = data.aws_caller_identity.current.account_id
  peer_region   = var.destination_region
  auto_accept   = false

  tags = {
    Side = "Requester"
  }
}

# Accepter's side of the connection.
resource "aws_vpc_peering_connection_accepter" "peer" {
  provider                  = aws.destination
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  auto_accept               = true

  tags = {
    Side = "Accepter"
  }
}
resource "aws_route" "source" {
  provider                  = aws.source
  count                     = length(data.aws_route_tables.source.ids)
  route_table_id            = tolist(data.aws_route_tables.source.ids)[count.index]
  destination_cidr_block    = data.aws_vpc.destination.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}
resource "aws_route" "destination" {
  provider                  = aws.destination
  count                     = length(data.aws_route_tables.destination.ids)
  route_table_id            = tolist(data.aws_route_tables.destination.ids)[count.index]
  destination_cidr_block    = data.aws_vpc.source.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

