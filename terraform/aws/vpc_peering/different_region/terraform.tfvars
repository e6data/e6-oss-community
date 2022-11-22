source_vpc         = "vpc-03b5f6f73fb2b5897" //The vpc having hive configured
destination_vpc    = "vpc-071c52baf4fd857a3" //The vpc having e6-engine configured
source_region      = "us-east-1"             //The region in which hive is configured
destination_region = "us-west-1"             //The region in which engine is configured
route_table_id     = "rtb-08fe04cd7a905a9bd" //The route table associated with subnet in which the hive metastore is present 
