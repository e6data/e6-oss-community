# e6-oss-community
# Hive Metastore


## GCP
To use Terraform to manage and deploy resources and infrastructure to GCP, you will need to use the GCP provider. You must configure the provider with the proper credentials before you can use it. This provider is maintained internally by the HashiCorp GCP Provider team. You can follow one of the methods mentioned in this [Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference).

Use the below configs for GCP hive metastore.

The Hive metastore is configured using the bootstrap script in terraform/gcp/hive_metastore/bootstrap_script.sh.

Go to [same_region](https://github.com/e6x-labs/e6-oss-community/tree/main/terraform/gcp/hive_metastore/) and execute the [**Execution commands**](#execution-commands) after updating **tfvars.**

### Variables

```bash
region = "<region for the hive metasore>"
network = "<network used for hive metasore>"
subnetwork = "<subnet used for hive metasore>"
instance_type = "<instance type for the hive metastore e2-standard-4>"
```

### Execution commands
```bash
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply
```
### Cleanup commands
```bash
terraform destroy 
```

## Contributing

Pull requests are welcome. For major changes, please open an issue first
to discuss what you would like to change.

Please make sure to update tests as appropriate.



