# e6-oss-community
# VPC Peering

VPC Network Peering enables you to connect VPC networks so that workloads in different VPC networks can communicate internally. Traffic stays within Cloud's network and doesn't traverse the public internet.

## GCP

Use the below configs for GCP peering.

### Same project for both networks

Go to [same_project](https://github.com/e6x-labs/e6-oss-community/tree/main/terraform/gcp/network_peering/same_project)  and execute the [**Execution commands**](#execution-commands) after updating **tfvars.**


### Different project for networks

Go to [different_project](https://github.com/e6x-labs/e6-oss-community/tree/main/terraform/gcp/network_peering/different_project) and execute the [**Execution commands**](#execution-commands) after updating **tfvars.**

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

[GCP network peering](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network_peering)