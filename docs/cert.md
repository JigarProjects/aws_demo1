# Domain registration
If you do not have a domain then you can buy it from Route 53 or any other domain registrars
If you already have a domain name then you can transfer it to AWS Route 53

# Creating TLS Certificate
Terraform script is configured to create a wildcard certificate for your domain. After creating the certificate, the script will also validate it using DNS validation. Afterwards, the validated certificate would be used by the Application Load Balancer to secure traffic.

# Renewing TLS Certificate
  - certifcate has create-before-destroy lifecycle
  - ELB Security Policy: ELBSecurityPolicy-2016-08 (TLS 1.2)
  - An alert is configured to notify you when certificate is about to expire
  - After creating a new certificate, load balancers need to be updated to use it (can be done with zero downtime)
