# e6-oss-community
# VPC Peering

VPC Network Peering enables you to connect VPC networks so that workloads in different VPC networks can communicate internally. Traffic stays within Cloud's network and doesn't traverse the public internet.

## AWS

-To use Terraform to manage and deploy resources and infrastructure to AWS, you will need to use the AWS provider. You must configure the provider with the proper credentials before you can use it. This provider is maintained internally by the HashiCorp AWS Provider team. You can follow one of the methods mentioned in this [document](https://linktodocumentation).

-In this terraform code, the routes are being modified in the route table of both the VPC's(Source and destination). The user should make sure that the private subnet is associated with a route table.
Use the below configs for AWS peering.

-To grant access to VPC peering resources, attach the below IAM policy to an IAM identity, such as a user, group, or role.
```bash
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
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
                "ec2:DescribeVpcAttribute",
                "ec2:DeleteRoute",
                "ec2:DeleteVpcPeeringConnection",
                "ec2:CreateTags"
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
terraform plan -var-file="terraform.tfvars" --out="e6.plan"
terraform apply "e6.plan"
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
