# Presto

Presto is an open-source SQL query engine that's fast, reliable, and efficient at scale. Use Presto to run interactive/ad hoc queries at sub-second performance for your high-volume apps.

## Presto on AWS using EMR

Amazon EMR Serverless is a new option in Amazon EMR that makes it easy and cost-effective for data engineers and analysts to run applications built using open-source big data frameworks such as Apache Spark, Hive or Presto, without having to tune, operate, optimize, and secure or manage clusters.




### Deployment
Go to [presto](https://github.com/e6x-labs/e6-oss-community/tree/main/presto/aws/presto_emr/) folder and execute the [**Execution commands**](#execution-commands) after updating **tfvars.**

### Variables
```bash
hive_host = "<ip on which hive host is running>"
hive_port = "<port on which hive host is running>"
cluster_name = "<name of the emr cluster>"
uuid = "<unique identifier eg. 111222>"
instance_count = "<the count of core instance>"
aws_account_id = "<account if for the aws account>"
enable_spot = "<for enabling the spot instance>"
bid_price = "<Bid price for each EC2 Spot instance>"

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

## Contributing

Pull requests are welcome. For major changes, please open an issue first
to discuss what you would like to change.

Please make sure to update tests as appropriate.

## References

[AWS EMR](https://aws.amazon.com/emr/)

[TERRAFORM BEST PRACTICES](https://spacelift.io/blog/terraform-tutorial)

[PRESTO EMR](https://docs.aws.amazon.com/emr/latest/ReleaseGuide/emr-presto.html)