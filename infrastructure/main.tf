provider "aws" {
  region = "eu-west-1"
}

provider "aws" {
  alias  = "us-east"
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

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "website" {
  origin {
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id   = "s3-website"
  }
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  # Remove aliases for now
  # aliases = ["santiagofischel.com"]

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

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = "personal-resume-website-tatofs distribution"
  }
}

resource "aws_route53_zone" "website" {
  name = "santiagofischel.com"
}

resource "aws_route53_record" "website_alias" {
  zone_id = aws_route53_zone.website.id
  name    = "santiagofischel.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.website.id
}

output "website_bucket_name" {
  value = aws_s3_bucket.website.id
}
