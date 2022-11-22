source_vpc      = "vpc-03b5f6f73fb2b5897" //The vpc having hive configured
destination_vpc = "vpc-0c5f69c4172c6092b" //The vpc having engine configured
region          = "us-east-1"             //The region in which hive and engine is configured
route_table_id  = "rtb-08fe04cd7a905a9bd" //The route table associated with subnet in which the hive metastore is present 
