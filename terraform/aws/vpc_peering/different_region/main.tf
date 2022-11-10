data "aws_caller_identity" "current" {}

# Requester's side of the connection.
resource "aws_vpc_peering_connection" "peer" {
  vpc_id        = var.destination_vpc
  peer_vpc_id   = var.source_vpc
  peer_owner_id = data.aws_caller_identity.current.account_id
  peer_region   = var.accept_region
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
