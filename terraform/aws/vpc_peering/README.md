# e6-oss-community
# VPC Peering

VPC Network Peering enables you to connect VPC networks so that workloads in different VPC networks can communicate internally. Traffic stays within Cloud's network and doesn't traverse the public internet.

## AWS

-In this terraform code, the routes are being modified in the main route table of the VPC. The user should make sure that the private subnet is attached to the main route table.
Use the below configs for AWS peering.

-By default, IAM users cannot create or modify VPC peering connections. To grant access to VPC peering resources, attach the below IAM policy to an IAM identity, such as a user, group, or role.
```bash
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AcceptVpcPeeringConnection",
                "ec2:AssociateRouteTable",
                "ec2:CreateRoute",
                "ec2:CreateVpcPeeringConnection",
                "ec2:DescribeRouteTables",
                "ec2:DescribeVpcPeeringConnections",
                "ec2:DescribeVpcs",
                "ec2:ModifyVpcPeeringConnectionOptions",
                "ec2:ReplaceRoute",
                "ec2:ReplaceRouteTableAssociation",
                "ec2:DescribeVpcAttribute"
            ],
            "Resource": "*"
        }
    ]
}
```

### Same region for both VPCs

Go to [same_region](https://github.com/e6x-labs/e6-oss-community/tree/main/terraform/aws/vpc_peering/same_region) and execute the [**Execution commands**](#execution-commands) after updating **tfvars.**


### Different regions for VPCs

Go to [different_region](https://github.com/e6x-labs/e6-oss-community/tree/main/terraform/aws/vpc_peering/different_region) and execute the [**Execution commands**](#execution-commands) after updating **tfvars.**

Vpc peering for different region might take 3-4 minutes to get active after running the terraform code.

Note : Make sure that the cluster and the data on which you query is in the same region.

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

## References
[AWS vpc peering](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_peering_connection)
