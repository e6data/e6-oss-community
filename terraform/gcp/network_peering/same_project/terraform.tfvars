source_network         = "e6data-source-vpc"                //The vpc having hive configured
destination_network    = "e6data-destination-vpc" //The vpc having engine configured
project                = "e6data-some-project"  //The project in which hive and engine is configured
workspace_name         = "work-1"            //The name of the e6data workspace
serverless_subnet_cidr = "10.12.0.0/28"         //cidr range for the serverless vpc
region                 = "us-central1"