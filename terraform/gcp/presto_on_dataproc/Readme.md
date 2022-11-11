
# Presto

Presto is an open-source SQL query engine that's fast, reliable, and efficient at scale. Use Presto to run interactive/ad hoc queries at sub-second performance for your high-volume apps.

## GCP

## Presto on GCP using Dataproc
Dataproc is a fully managed and highly scalable service for running Apache Hadoop, Apache Spark, Apache Flink, Presto, and 30+ open source tools and frameworks. Use Dataproc for data lake modernization, ETL, and secure data science, at scale, integrated with Google Cloud


### Deployment
Go to [presto](https://github.com/e6x-labs/e6-oss-community/tree/main/presto/gcp/presto_dataproc/) folder and execute the [**Execution commands**](#execution-commands) after updating **tfvars.**

### Variables
```bash
network = "<GCP network>"
subnetwork = "<GCP subnetwork>"
hive_host = "<ip on which hive host is running>"
hive_port = "<port on which hive host is running>"
cluster_name = "<name of the emr cluster>"
uuid = "<unique identifier eg. 111222>"
instance_count = "<the count of core instance>"
region = "<the region for the emr>"
enable_spot = "<for enabling the spot instance>"

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

[GCP Dataproc](https://cloud.google.com/dataproc)
[TERRAFORM BEST PRACTICES](https://cloud.google.com/docs/terraform/best-practices-for-terraform)
[PRESTO DATAPROC](https://cloud.google.com/dataproc/docs/tutorials/presto-dataproc)