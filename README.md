# Building Better Clouds

**Terraforming secure, compliant cloud environments for the AI era.**

A hands-on GRC + DevSecOps project focused on CMMC-compliant infrastructure, AI governance, and automation.

## Current Architecture
- **VPC** with public/private subnets across 2 AZs (us-west-2)
- Internet Gateway + NAT Gateway for secure outbound access
- VPC Flow Logs enabled (evidence collection to S3)
- Encrypted S3 bucket for compliance artifacts

## Goals
- IaC with Terraform for repeatable secure deployments
- Automated compliance monitoring
- AI workload governance (risk scoring, evidence collection)
- Portfolio showcase for GRC Engineering / Cloud Compliance roles

## Tech Stack
- Terraform (IaC)
- AWS (VPC, S3, Flow Logs)
- Python (planned automation + risk models)
- CMMC / NIST alignment

## Deployment
```bash
terraform init
terraform plan
terraform apply