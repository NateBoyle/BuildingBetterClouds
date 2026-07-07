# Building Better Clouds

**Terraforming secure, compliant cloud environments for the AI era.**

A hands-on GRC + DevSecOps portfolio project focused on CMMC-compliant infrastructure, AI workload governance, and automated evidence collection.

## Architecture Highlights

- **VPC**: Multi-AZ public/private subnets with NAT Gateway
- **Evidence Collection**: VPC Flow Logs → Encrypted S3 bucket (versioned + lifecycle)
- **Security**: Layered Security Groups (public bastion + private)
- **Compute**:
  - Bastion EC2 instance (public subnet)
  - SageMaker Domains:
    - `custom-models` domain
    - `prebuilt-models` domain
- **Compliance**: CMMC-aligned tagging, encryption, private networking, audit logs

## Tech Stack

- Terraform (IaC)
- AWS (VPC, S3, EC2, SageMaker)
- Security & Compliance best practices

## Project Structure
├── main.tf
├── networking.tf
├── s3.tf
├── iam.tf
├── security.tf
├── ec2.tf
├── sagemaker.tf
├── outputs.tf
└── README.md