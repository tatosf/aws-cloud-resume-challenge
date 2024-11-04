# Configure the AWS Provider
provider "aws" {
  region = "eu-west-1"
}

# Use data source for existing bucket
data "aws_s3_bucket" "website" {
  bucket = "personal-resume-website-tatofs"
}

# Enable website hosting
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = data.aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
}

# Make bucket public
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = data.aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Add bucket policy for public read access
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

# Output the website URL
output "website_url" {
  value = data.aws_s3_bucket.website.website_endpoint
}