# create cert use DNS to validate
resource "aws_acm_certificate" "star_domain_cert" {
  domain_name       = "*.${var.domain_name}"
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

data "aws_route53_zone" "main_domain" {
  name         = var.domain_name
  private_zone = false
}

# add DNS entry to route53
resource "aws_route53_record" "dns_record_for_validation" {
  for_each = {
    for dvo in aws_acm_certificate.star_domain_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id = data.aws_route53_zone.main_domain.zone_id
}

resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.star_domain_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.dns_record_for_validation : record.fqdn]
}
