
# Output the website endpoint
output "website_url" {
  value = aws_s3_bucket_website_configuration.website.website_endpoint
  description = "URL of the S3 website bucket"
}
# Configure the AWS Provider
provider "aws" {
  region = "eu-west-1"
}

# Use data source instead of resource for existing bucket
data "aws_s3_bucket" "website" {
  bucket = "personal-resume-website-tatofs"
}

# Website configuration
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = data.aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
}

# Public access block
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = data.aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Bucket policy
resource "aws_s3_bucket_policy" "website" {
  bucket = data.aws_s3_bucket.website.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${data.aws_s3_bucket.website.arn}/*"
      }
    ]
  })
}