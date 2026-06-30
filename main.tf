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

variable "environment" {
  default = "dev"
}

variable "project_name" {
  default = "building-better-clouds"
}

# VPC - Private network foundation
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
    Compliance  = "CMMC"
    Project     = var.project_name
  }
}

# Encrypted S3 bucket for evidence
resource "aws_s3_bucket" "evidence" {
  bucket = "${var.project_name}-evidence-${var.environment}"

  tags = {
    Name        = "GRC-Evidence-Storage"
    Compliance  = "CMMC"
    Project     = var.project_name
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

output "vpc_id" {
  value = aws_vpc.main.id
}

output "evidence_bucket" {
  value = aws_s3_bucket.evidence.bucket
}