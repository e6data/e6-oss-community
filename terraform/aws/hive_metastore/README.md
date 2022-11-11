# e6-oss-community
# Hive Metastore


## AWS

Use the below variables for AWS hive metastore.

Go to [here](https://github.com/e6x-labs/e6-oss-community/tree/main/terraform/aws/hive_metastore/) and execute the [**Execution commands**](#execution-commands) after updating **tfvars.**

### Variables

```bash
vpc_id = "<vpc id for hive metastore>"
instance_type = "<instance type eg. t3.micro>"
instance_profile_arn = "<instance profike arn>"
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



