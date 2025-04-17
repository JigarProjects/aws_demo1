Prerequisite

1. Create and use a non-root IAM user

2. Set it up using
- Run 'aws configure' or 
- set AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY 

3. Create s3 bucket to store terraform state file; update backend.tf file
4. Create dyanamodb table; update backend.tf file

This terraform role creates 2 VPCs
