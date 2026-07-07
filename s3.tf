# S3 Evidence Bucket (improved)
resource "aws_s3_bucket" "evidence" {
  bucket = "${var.project_name}-evidence-${var.environment}"

  tags = {
    Name        = "GRC-Evidence-Storage"
    Environment = var.environment
    Compliance  = "CMMC"
    Project     = var.project_name
  }
}

resource "aws_s3_bucket_versioning" "evidence" {
  bucket = aws_s3_bucket.evidence.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "evidence_encryption" {
  bucket = aws_s3_bucket.evidence.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "evidence" {
  bucket = aws_s3_bucket.evidence.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket Policy for VPC Flow Logs
resource "aws_s3_bucket_policy" "evidence_flow_logs" {
  bucket = aws_s3_bucket.evidence.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowFlowLogs"
        Effect    = "Allow"
        Principal = { Service = "vpc-flow-logs.amazonaws.com" }
        Action    = ["s3:PutObject"]
        Resource  = "${aws_s3_bucket.evidence.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "evidence" {
  bucket = aws_s3_bucket.evidence.id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"

    filter {
      prefix = ""   # Applies to all objects
    }

    expiration {
      days = 365   # Adjust as needed for compliance
    }
  }
}