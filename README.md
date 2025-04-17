Prerequisite

* AWS setup
1. Create and use a non-root IAM user
2. Create s3 bucket to store terraform state file; update backend.tf file
3. Create dyanamodb table; update backend.tf file

* On your machine
4. Install AWS CLI on your machine and configure it
- Run 'aws configure' or 
- set AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY 
5. Run 'terraform init' - it would perform initalization tasks like downloading AWS provider

* afterwards
6. Run 'terraform plan' - to check what changes would be applied
7. Run 'terraform apply' - to make changes

This terraform role creates 2 VPCs
