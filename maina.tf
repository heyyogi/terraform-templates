provider "aws" {
  region = "ap-south-1"
}

resource "aws_s3_bucket" "static_site" {
  bucket = "heyyogi-static-site"
  acl    = "public-read"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

resource "aws_s3_bucket_policy" "public_access" {
  bucket = aws_s3_bucket.static_site.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.static_site.arn}/*"
      }
    ]
  })
}

resource "aws_s3_object" "index" {
  bucket = aws_s3_bucket.static_site.id
  key    = "index.html"
  source = "${path.module}/index.html"
  acl    = "public-read"
  content_type = "text/html"
}

resource "aws_s3_object" "error" {
  bucket = aws_s3_bucket.static_site.id
  key    = "error.html"
  source = "${path.module}/error.html"
  acl    = "public-read"
  content_type = "text/html"
}