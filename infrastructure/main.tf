# Provider for the main region (eu-west-1)
provider "aws" {
  region = "eu-west-1"
}

# Provider for ACM certificate (MUST be in us-east-1 for CloudFront)
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

# Create S3 Bucket
resource "aws_s3_bucket" "website" {
  bucket = "personal-resume-website-tatofs"
}

resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "website" {
  depends_on = [aws_s3_bucket_public_access_block.website]
  bucket = aws_s3_bucket.website.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website.arn}/*"
      },
    ]
  })
}

# Configure website hosting
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Create Route 53 Zone
resource "aws_route53_zone" "website" {
  name = "santiagofischel.com"
}

# Create Route 53 record to point domain to CloudFront
resource "aws_route53_record" "website" {
  zone_id = aws_route53_zone.website.id
  name    = "santiagofischel.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id               = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}

# Create ACM Certificate (in us-east-1)
resource "aws_acm_certificate" "website" {
  provider          = aws.us-east-1
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
  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.website.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
  depends_on             = [aws_route53_record.cert_validation]
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "website" {
  depends_on = [aws_acm_certificate_validation.website]

  origin {
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id   = "s3-website"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
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

  # Add custom error response to redirect 404 to index.html for SPA support
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }
}

# Outputs
output "nameservers" {
  value       = aws_route53_zone.website.name_servers
  description = "Nameservers for the Route53 zone. Update these in your domain registrar."
}

output "cloudfront_domain" {
  value = aws_cloudfront_distribution.website.domain_name
}

output "certificate_arn" {
  value = aws_acm_certificate.website.arn
}

# Add CloudFront distribution ID output for GitHub Actions
output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.website.id
  description = "CloudFront Distribution ID for cache invalidation"
}

# Add website endpoint output
output "website_endpoint" {
  value = aws_s3_bucket_website_configuration.website.website_endpoint
  description = "S3 static website hosting endpoint"
}