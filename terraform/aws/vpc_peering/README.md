# e6-oss-community
# VPC Peering

VPC Network Peering enables you to connect VPC networks so that workloads in different VPC networks can communicate internally. Traffic stays within Cloud's network and doesn't traverse the public internet.

## AWS

Use the below configs for AWS peering.
### Same region for both VPCs

Go to [same_region](https://github.com/e6x-labs/e6-oss-community/tree/main/terraform/aws/vpc_peering/same_region) and execute the [**Execution commands**](#execution-commands) after updating **tfvars.**


### Different regions for VPCs

Go to [different_region](https://github.com/e6x-labs/e6-oss-community/tree/main/terraform/aws/vpc_peering/different_region) and execute the [**Execution commands**](#execution-commands) after updating **tfvars.**

### Execution commands
```bash
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply
```

## Contributing

Pull requests are welcome. For major changes, please open an issue first
to discuss what you would like to change.

Please make sure to update tests as appropriate.

## References
[AWS vpc peering](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_peering_connection)
