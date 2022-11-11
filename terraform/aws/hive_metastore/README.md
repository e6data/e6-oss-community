# Hive Metastore


## AWS

Use the below variables for AWS hive metastore.

Execute the [**Execution commands**](#execution-commands) after updating **tfvars.**

### Variables

```bash
vpc_id = "<vpc id where hive metastore needs to be created>"
instance_type = "<instance type eg. t3.medium>"
instance_profile_arn = "<instance profike arn>" ### EC2 instance profile with S3 read only access
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



