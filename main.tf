terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"   
}

# Example: Secure S3 bucket for compliance evidence (CMMC-friendly)
resource "aws_s3_bucket" "evidence" {
  bucket = "building-better-clouds-evidence-${var.environment}"

  tags = {
    Name        = "GRC-Evidence-Storage"
    Compliance  = "CMMC"
    Project     = "BuildingBetterClouds"
  }
}

variable "environment" {
  default = "dev"
}

output "evidence_bucket_name" {
  value = aws_s3_bucket.evidence.bucket
}