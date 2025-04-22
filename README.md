## Prerequisites

### AWS Setup
1. Create and use a non-root IAM user.
2. Create an S3 bucket to store the Terraform state file and update the `backend.tf` file accordingly.
3. Create a DynamoDB table and update the `backend.tf` file to enable state locking.

### Local Machine Setup
4. Install the AWS CLI on your machine and configure it:
    - Run `aws configure`, or
    - Set the environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.
5. Run `terraform init` to perform initialization tasks, such as downloading the AWS provider.

### Deployment Steps
6. Run `terraform plan` to preview the changes that will be applied.
7. Run `terraform apply` to apply the changes and deploy the infrastructure.

---

## Overview

This Terraform configuration creates two VPCs.

- **VPC-1**: Hosts the voting application. The application code is available at [vote_cats_dogs](https://github.com/JigarProjects/vote_cats_dogs).
- **VPC-2**: To be continued

#### TLS Security 

- Register domain in AWS (route53)
- Terrarofm can create certificate; also do validation using DNS
