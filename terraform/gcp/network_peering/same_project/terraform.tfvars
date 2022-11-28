source_network         = "default"                //The vpc having hive configured
destination_network    = "e6data-ninjaturtle-vpc" //The vpc having engine configured
project                = "proven-outpost-351604"  //The project in which hive and engine is configured
workspace_name         = "ninjaturtle"            //The name of the e6data workspace
serverless_subnet_cidr = "192.168.4.0/28"         //cidr range for the serverless vpc
