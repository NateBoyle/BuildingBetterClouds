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

# VPC
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

# Subnets (unchanged)
resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone = "us-west-2${["a", "b"][count.index]}"

  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-${["a", "b"][count.index]}"
    Environment = var.environment
    Compliance  = "CMMC"
    Tier        = "public"
    Project     = var.project_name
  }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 2)
  availability_zone = "us-west-2${["a", "b"][count.index]}"

  tags = {
    Name        = "${var.project_name}-private-${["a", "b"][count.index]}"
    Environment = var.environment
    Compliance  = "CMMC"
    Tier        = "private"
    Project     = var.project_name
  }
}

# Internet Gateway, Route Tables, NAT (unchanged from last version)
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
    Compliance  = "CMMC"
    Project     = var.project_name
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    Environment = var.environment
    Compliance  = "CMMC"
    Project     = var.project_name
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "${var.project_name}-nat-eip"
    Environment = var.environment
    Compliance  = "CMMC"
    Project     = var.project_name
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name        = "${var.project_name}-nat"
    Environment = var.environment
    Compliance  = "CMMC"
    Project     = var.project_name
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-private-rt"
    Environment = var.environment
    Compliance  = "CMMC"
    Project     = var.project_name
  }
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# VPC Flow Logs → Evidence S3 Bucket
resource "aws_flow_log" "main" {
  vpc_id                = aws_vpc.main.id
  traffic_type          = "ALL"
  log_destination_type  = "s3"
  log_destination       = aws_s3_bucket.evidence.arn
  log_format            = "$${version} $${account-id} $${interface-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${start} $${end} $${action} $${log-status}"

  tags = {
    Name        = "${var.project_name}-flow-logs"
    Environment = var.environment
    Compliance  = "CMMC"
    Project     = var.project_name
  }
}

# Simplified IAM Role for Flow Logs to S3
resource "aws_iam_role" "flow_logs" {
  name = "${var.project_name}-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "${var.project_name}-flow-logs-role"
    Environment = var.environment
    Compliance  = "CMMC"
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy" "flow_logs" {
  role = aws_iam_role.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:PutObject"
      ]
      Resource = "${aws_s3_bucket.evidence.arn}/*"
    }]
  })
}

# S3 Evidence Bucket
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

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "evidence_bucket" {
  value = aws_s3_bucket.evidence.bucket
}

output "flow_logs_role" {
  value = aws_iam_role.flow_logs.name
}