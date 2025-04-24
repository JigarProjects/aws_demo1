# create cert use DNS to validate - only if domain_name is provided
resource "aws_acm_certificate" "star_domain_cert" {
  count = length(var.domain_name) > 0 ? 1 : 0

  domain_name       = "*.${var.domain_name}"
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

data "aws_route53_zone" "main_domain" {
  count = length(var.domain_name) > 0 ? 1 : 0
  name         = var.domain_name
  private_zone = false
}

# add DNS entry to route53 - only if domain_name is provided
resource "aws_route53_record" "dns_record_for_validation" {
  for_each = length(var.domain_name) > 0 ? {
    for dvo in aws_acm_certificate.star_domain_cert[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id = data.aws_route53_zone.main_domain[0].zone_id
}

resource "aws_acm_certificate_validation" "cert_validation" {
  count = length(var.domain_name) > 0 ? 1 : 0

  certificate_arn         = aws_acm_certificate.star_domain_cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.dns_record_for_validation : record.fqdn]
}
