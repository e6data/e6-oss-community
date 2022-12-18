# e6-oss-community
# VPC Peering

VPC Network Peering enables you to connect VPC networks so that workloads in different VPC networks can communicate internally. Traffic stays within Cloud's network and doesn't traverse the public internet.

IAM permissions for creating and deleting VPC Network Peering are included as part of the Compute Network Admin (roles/compute.networkAdmin), permissions to create serverless vpc is included in (roles/vpcaccess.user) and permissions to edit the cloud function is included in the (roles/cloudfunctions.admin) role.

## GCP

To use Terraform to manage and deploy resources and infrastructure to GCP, you will need to use the GCP provider. You must configure the provider with the proper credentials before you can use it. This provider is maintained internally by the HashiCorp GCP Provider team. You can follow one of the methods mentioned in this [Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference).

## Basic network peering between two networks

Google Cloud VPC Network Peering connects two Virtual Private Cloud (VPC) networks so that resources in each network can communicate with each other:

Go to [basic_network_peering](https://github.com/e6x-labs/e6-oss-community/tree/serverless_gcp/terraform/gcp/network_peering/network_peering_basic)  and execute the [**Execution commands**](#execution-commands) after updating **tfvars.**

Note:
* We can use the same terraform code for the VPC's within the same project and two different projects.


### terraform tfvars file

```bash
source_network      = "<source_network>"      //The source network ID
destination_network = "<destination network>" //The destination network ID
source_project      = "<source project>"      //The project in which source network is configured
destination_project = "<destination project>" //The project in which destination network is configured
source_region       = "<source region>"       //The region in which source network is configured
destination_region  = "<destination region>"  //The region in which destination network is configured
```

### Execution commands

```bash
terraform init
terraform plan 
terraform apply 
```
### Cleanup commands
```bash
terraform destroy 
```


## Network peering between a VPC and a serverless VPC which is connected to cloud function

The cloud function does not have a network attached to it by default. The VPC network peering betweeen the meta function and the  hive metastore is possible if we have a subnetwork attached to the meta function.

We can use a Serverless VPC Access connector to connect the cloud function directly to a Virtual Private Cloud (VPC) network, allowing access to cloud function with an internal IP address.

Go to [network_peering_serverless](https://github.com/e6x-labs/e6-oss-community/tree/serverless_gcp/terraform/gcp/network_peering/network_peering_serverless)  and execute the [**Execution commands**](#execution-commands) after updating **tfvars.**


### terraform tfvars file
Note:
* For the variable serverless_subnet_cidr
    * IP range must be an unused /28 CIDR range in the same VPC network, such as 10.8.0.0/28. i.e.,mask must be 28.
    * Ensure that the range does not overlap with an existing subnet. 


```bash
source_network         = <source_network>              //The vpc having hive configured
destination_network    = <destination network>         //The vpc having engine configured
project                = <project>                     //The project in which hive and engine is configured
workspace_name         = <workspace_name>              //The name of the e6data workspace
serverless_subnet_cidr = <serverless_subnet_cidr>      //cidr range for the serverless vpc
```

### Execution commands

The meta function must be imported to be managed by the terraform to edit the function and attach serverless VPC to it. Please make sure to **replace the {workspace-name}** with your own e6data workspace name. 
```bash
terraform init
terraform import google_cloudfunctions_function.meta-function e6data-{workspace-name}-meta
terraform plan 
terraform apply -var action="create"
```
### Cleanup commands
```bash
terraform apply -var action="destroy" 
```

## Contributing

Pull requests are welcome. For major changes, please open an issue first
to discuss what you would like to change.

Please make sure to update tests as appropriate.

## References

[GCP network peering](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network_peering)
