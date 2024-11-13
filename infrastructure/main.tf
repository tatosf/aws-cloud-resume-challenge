# Provider for the main region (eu-west-1)
provider "aws" {
  region = "eu-west-1"
}

# Provider for ACM certificate (MUST be in us-east-1 for CloudFront)
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"  # Changed from eu-west-1 to us-east-1
}

# Create ACM Certificate (in us-east-1)
resource "aws_acm_certificate" "website" {
  provider          = aws.us-east-1  # Changed from eu-west-1 to us-east-1
  domain_name       = "santiagofischel.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Create DNS validation records for the certificate
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.website.domain_validation_options : dvo.domain_name => {
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
  zone_id         = aws_route53_zone.website.id
}

# Certificate validation
resource "aws_acm_certificate_validation" "website" {
  provider                = aws.us-east-1  # Must match the certificate provider
  certificate_arn         = aws_acm_certificate.website.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
  depends_on             = [aws_route53_record.cert_validation]  # Added depends_on
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "website" {
  depends_on = [aws_acm_certificate_validation.website]  # Added depends_on

  origin {
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id   = "s3-website"
  }
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = ["santiagofischel.com"]

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-website"
    min_ttl                = 0
    default_ttl            = 300
    max_ttl                = 1200
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.website.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

output "nameservers" {
  value       = aws_route53_zone.website.name_servers
  description = "Nameservers for the Route53 zone. Update these in your domain registrar."
}

# Add CloudFront domain output for verification
output "cloudfront_domain" {
  value = aws_cloudfront_distribution.website.domain_name
}

# Add certificate ARN output for verification
output "certificate_arn" {
  value = aws_acm_certificate.website.arn
}