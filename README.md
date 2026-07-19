# Building Better Clouds

**Terraforming secure, compliant cloud environments for the AI era.**

A hands-on GRC + DevSecOps portfolio project focused on CMMC-aligned infrastructure, AI workload governance, and automated evidence collection.

## Goals

- Build a reusable AWS baseline with Terraform that supports **auditability**, **least-privilege networking**, and **encrypted evidence storage**
- Demonstrate **CMMC-aligned** controls: logging, monitoring, configuration tracking, and resource tagging
- Host AI experimentation safely via **SageMaker domains** in private subnets
- Collect continuous compliance evidence in a single **S3 evidence bucket**

## Architecture Highlights

| Area | What this project deploys |
|------|---------------------------|
| **Networking** | VPC (10.0.0.0/16), multi-AZ public/private subnets (`us-west-2a/b`), Internet Gateway, NAT Gateway, route tables |
| **Evidence collection** | VPC Flow Logs, CloudTrail, and AWS Config all deliver to one encrypted, versioned S3 evidence bucket |
| **Security** | Layered security groups (public bastion/web + private app/SageMaker) |
| **Monitoring** | Multi-region CloudTrail with log file validation, CloudWatch Logs metric filters/alarms, SNS security alerts topic |
| **Configuration governance** | AWS Config recorder + managed rules (S3 public access, encryption, root MFA, IAM password policy) |
| **Compute** | Bastion EC2 (public subnet); SageMaker domains for custom and pre-built models (private subnets) |
| **Compliance posture** | CMMC tags, encryption at rest (S3), private networking for AI workloads, 365-day log retention targets |

### Evidence bucket layout

Bucket name pattern: `{project_name}-evidence-{environment}`  
Default: `building-better-clouds-evidence-dev`

| Prefix | Source |
|--------|--------|
| (flow logs objects) | VPC Flow Logs |
| `cloudtrail/` | CloudTrail management events |
| `config/` | AWS Config snapshots / history |

S3 features: versioning, AES-256 encryption, public access block, lifecycle expiration (365 days), bucket policy for Flow Logs + CloudTrail + Config.

### Monitoring & alarms

CloudTrail writes to S3 **and** CloudWatch Logs group:

`/aws/cloudtrail/building-better-clouds` (365-day retention)

Metric filters publish under namespace **`CMMC/CloudTrail`**. Alarms notify SNS topic `building-better-clouds-security-alerts`:

| Alarm focus | CMMC-oriented intent |
|-------------|----------------------|
| Unauthorized / AccessDenied API calls | AU / SI – detect denied activity |
| Root account usage | AC / AU – privileged account monitoring |
| Console sign-in without MFA | IA / AC – authentication hygiene |
| Security group changes | CM / SC – network control changes |
| Network ACL changes | CM / SC – network control changes |

### AWS Config managed rules

- `S3_BUCKET_PUBLIC_READ_PROHIBITED`
- `S3_BUCKET_PUBLIC_WRITE_PROHIBITED`
- `ENCRYPTED_VOLUMES`
- `ROOT_ACCOUNT_MFA_ENABLED`
- `IAM_PASSWORD_POLICY`

## Tech Stack

- **IaC**: Terraform (AWS provider `~> 5.0`)
- **Region**: `us-west-2`
- **AWS services**: VPC, EC2, S3, IAM, SageMaker, CloudTrail, Config, CloudWatch, SNS
- **Practices**: tagging for compliance, encryption, private AI workloads, centralized audit evidence

## Project Structure

```
├── main.tf           # Provider, variables (environment, project_name, key_name)
├── networking.tf     # VPC, subnets, IGW, NAT, route tables, VPC Flow Logs
├── s3.tf             # Evidence bucket (encryption, versioning, lifecycle, policy)
├── iam.tf            # IAM role for VPC Flow Logs
├── security.tf       # Public and private security groups
├── ec2.tf            # Bastion instance (Amazon Linux 2023)
├── sagemaker.tf      # SageMaker execution role + custom / prebuilt domains
├── monitoring.tf     # CloudTrail, AWS Config, CloudWatch alarms, SNS
├── outputs.tf        # VPC, subnets, evidence bucket, trail, Config, SNS
└── README.md
```

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) installed
- AWS credentials configured for an account with permissions to create the resources above
- An EC2 key pair in `us-west-2` matching `var.key_name` (default: `building-better-clouds-key`)

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `environment` | `dev` | Environment tag / naming suffix |
| `project_name` | `building-better-clouds` | Resource name prefix |
| `key_name` | `building-better-clouds-key` | EC2 key pair for the bastion |

## Outputs

| Output | Description |
|--------|-------------|
| `vpc_id` | Main VPC ID |
| `public_subnet_ids` / `private_subnet_ids` | Subnet IDs |
| `evidence_bucket` | S3 evidence bucket name |
| `flow_logs_role` | Flow Logs IAM role name |
| `cloudtrail_name` | CloudTrail trail name |
| `config_recorder_name` | AWS Config recorder name |
| `security_alerts_topic_arn` | SNS topic for security alarms |

## Terraform commands

```bash
# Initialize providers/plugins
terraform init

# Review the planned changes
terraform plan

# Apply the configuration
terraform apply

# Inspect resource outputs
terraform output

# Tear down all managed resources
terraform destroy
```

> **Note:** Non-empty or versioned S3 objects may need to be removed before `terraform destroy` succeeds. CloudTrail and Config may continue writing until those resources are destroyed.

## Validating in the AWS Console

Use region **US West (Oregon) `us-west-2`**.

1. **S3** → `building-better-clouds-evidence-dev`  
   - Versioning and encryption on; public access blocked  
   - Objects under `cloudtrail/` and `config/` after the services start writing  

2. **CloudTrail** → Trails → `building-better-clouds-trail`  
   - Logging on, multi-region, log file validation enabled  
   - Event history shows recent management events  

3. **CloudWatch** → Log groups → `/aws/cloudtrail/building-better-clouds`  
   - Retention 365 days; metric filters present  

4. **CloudWatch** → Alarms  
   - Five security alarms wired to the SNS topic  

5. **SNS** → `building-better-clouds-security-alerts`  
   - Topic exists (add an email subscription if you want notifications)  

6. **Config** → Recorder / Rules  
   - Recorder enabled; delivery to the evidence bucket  
   - Managed rules evaluating (first results can take several minutes)  

## CMMC alignment (portfolio framing)

This is a **learning / portfolio** baseline, not a certified enclave. It maps practice areas such as:

- **AU** – CloudTrail, Flow Logs, CloudWatch retention  
- **CM** – AWS Config + change-detection alarms  
- **AC / IA** – private subnets for AI, MFA/root monitoring signals  
- **SC** – encryption, public access blocks, layered security groups  
- **SI** – unauthorized API and security-control change alarms  

Evidence for reviews can be exported from S3, CloudTrail event history, Config compliance, and alarm history.

## Roadmap ideas

- SNS email (or ChatOps) subscription for security alerts  
- Additional Config rules and conformance packs  
- GuardDuty / Security Hub integration  
- Stricter bastion ingress (replace `0.0.0.0/0` SSH)  
- Remote Terraform state backend and CI plan/apply  

---

Built as a hands-on GRC + DevSecOps project for secure, observable AWS environments supporting AI workloads.
