# Changelog

All notable changes to this project are documented in this file.

## 2026-07-19

### Added

- `monitoring.tf` — CMMC-aligned monitoring and audit stack for `us-west-2`:
  - Multi-region CloudTrail with log file validation, S3 delivery to the evidence bucket (`cloudtrail/` prefix), and CloudWatch Logs integration
  - AWS Config configuration recorder, delivery channel (`config/` prefix), and managed rules (S3 public read/write prohibited, encrypted volumes, root MFA, IAM password policy)
  - CloudWatch metric filters and alarms (unauthorized API calls, root account usage, console sign-in without MFA, security group changes, NACL changes)
  - SNS topic `building-better-clouds-security-alerts` for alarm notifications
- Terraform outputs for `cloudtrail_name`, `config_recorder_name`, and `security_alerts_topic_arn`
- `CHANGELOG.md`

### Changed

- `s3.tf` — Expanded evidence bucket policy to allow CloudTrail and AWS Config writes (alongside VPC Flow Logs)
- `README.md` — Documented monitoring, evidence bucket layout, Config rules, outputs, prerequisites, Terraform commands, console validation, and CMMC portfolio framing
