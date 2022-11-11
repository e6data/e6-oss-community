# e6-oss-community
# Hive Metastore


## GCP

Use the below configs for GCP hive metastore.

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

## Contributing

Pull requests are welcome. For major changes, please open an issue first
to discuss what you would like to change.

Please make sure to update tests as appropriate.



