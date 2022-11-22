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

data "aws_route_table" "pvt" {
  provider = aws.destination
  vpc_id   = var.destination_vpc

  filter {
    name   = "tag:aws:cloudformation:logical-id"
    values = ["e6pvtRouteTable"]
  }
}
data "aws_route_table" "pub" {
  provider = aws.destination
  vpc_id   = var.destination_vpc

  filter {
    name   = "tag:aws:cloudformation:logical-id"
    values = ["e6pubRouteTable"]
  }
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
  route_table_id            = var.route_table_id
  destination_cidr_block    = data.aws_vpc.destination.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}
resource "aws_route" "destination-pvt" {
  provider                  = aws.destination
  route_table_id            = data.aws_route_table.pvt.id
  destination_cidr_block    = data.aws_vpc.source.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}
resource "aws_route" "destination-pub" {
  provider                  = aws.destination
  route_table_id            = data.aws_route_table.pub.id
  destination_cidr_block    = data.aws_vpc.source.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

