# Hive Metastore


## AWS

-To use Terraform to manage and deploy resources and infrastructure to AWS, you will need to use the AWS provider. You must configure the provider with the proper credentials before you can use it. This provider is maintained internally by the HashiCorp AWS Provider team. You can follow one of the methods mentioned in this [document](https://spacelift.io/blog/terraform-aws-provider).

Use the below variables for AWS hive metastore.


The Hive metastore is configured using the bootstrap script in terraform/aws/hive_metastore/bootstrap_script.sh.

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
### Cleanup commands
```bash
terraform destroy 
```

## Contributing

Pull requests are welcome. For major changes, please open an issue first
to discuss what you would like to change.

Please make sure to update tests as appropriate.



