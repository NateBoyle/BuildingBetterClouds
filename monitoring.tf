# monitoring.tf
# CloudTrail, AWS Config, and CloudWatch alarms for CMMC-aligned audit & monitoring (us-west-2)

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# CloudWatch Log Group (CloudTrail delivery)
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/${var.project_name}"
  retention_in_days = 365

  tags = {
    Name        = "${var.project_name}-cloudtrail-logs"
    Environment = var.environment
    Compliance  = "CMMC"
    Project     = var.project_name
  }
}

# -----------------------------------------------------------------------------
# IAM – CloudTrail → CloudWatch Logs
# -----------------------------------------------------------------------------

resource "aws_iam_role" "cloudtrail_cloudwatch" {
  name = "${var.project_name}-cloudtrail-cw-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "cloudtrail.amazonaws.com" }
    }]
  })

  tags = {
    Name        = "${var.project_name}-cloudtrail-cw-role"
    Environment = var.environment
    Compliance  = "CMMC"
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy" "cloudtrail_cloudwatch" {
  name = "${var.project_name}-cloudtrail-cw-policy"
  role = aws_iam_role.cloudtrail_cloudwatch.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# CloudTrail (audit logs → evidence S3 + CloudWatch)
# -----------------------------------------------------------------------------

resource "aws_cloudtrail" "main" {
  name                          = "${var.project_name}-trail"
  s3_bucket_name                = aws_s3_bucket.evidence.id
  s3_key_prefix                 = "cloudtrail"
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  enable_logging                = true

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_cloudwatch.arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  depends_on = [
    aws_s3_bucket_policy.evidence_flow_logs,
    aws_iam_role_policy.cloudtrail_cloudwatch
  ]

  tags = {
    Name        = "${var.project_name}-trail"
    Environment = var.environment
    Compliance  = "CMMC"
    Project     = var.project_name
  }
}

# -----------------------------------------------------------------------------
# IAM – AWS Config
# -----------------------------------------------------------------------------

resource "aws_iam_role" "config" {
  name = "${var.project_name}-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "config.amazonaws.com" }
    }]
  })

  tags = {
    Name        = "${var.project_name}-config-role"
    Environment = var.environment
    Compliance  = "CMMC"
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "config" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_iam_role_policy" "config_s3" {
  name = "${var.project_name}-config-s3-policy"
  role = aws_iam_role.config.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketAcl",
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.evidence.arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject"]
        Resource = "${aws_s3_bucket.evidence.arn}/config/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# AWS Config (configuration recorder + delivery to evidence S3)
# -----------------------------------------------------------------------------

resource "aws_config_configuration_recorder" "main" {
  name     = "${var.project_name}-recorder"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }

  depends_on = [aws_iam_role_policy_attachment.config]
}

resource "aws_config_delivery_channel" "main" {
  name           = "${var.project_name}-config-delivery"
  s3_bucket_name = aws_s3_bucket.evidence.id
  s3_key_prefix  = "config"

  depends_on = [
    aws_config_configuration_recorder.main,
    aws_s3_bucket_policy.evidence_flow_logs
  ]
}

resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.main]
}

# Basic CMMC-aligned Config managed rules
resource "aws_config_config_rule" "s3_public_read_prohibited" {
  name = "${var.project_name}-s3-public-read-prohibited"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }

  depends_on = [aws_config_configuration_recorder_status.main]

  tags = {
    Name        = "${var.project_name}-s3-public-read-prohibited"
    Environment = var.environment
    Compliance  = "CMMC"
    Project     = var.project_name
  }
}

resource "aws_config_config_rule" "s3_public_write_prohibited" {
  name = "${var.project_name}-s3-public-write-prohibited"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_WRITE_PROHIBITED"
  }

  depends_on = [aws_config_configuration_recorder_status.main]

  tags = {
    Name        = "${var.project_name}-s3-public-write-prohibited"
    Environment = var.environment
    Compliance  = "CMMC"
    Project     = var.project_name
  }
}

resource "aws_config_config_rule" "encrypted_volumes" {
  name = "${var.project_name}-encrypted-volumes"

  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }

  depends_on = [aws_config_configuration_recorder_status.main]

  tags = {
    Name        = "${var.project_name}-encrypted-volumes"
    Environment = var.environment
    Compliance  = "CMMC"
    Project     = var.project_name
  }
}

resource "aws_config_config_rule" "root_mfa_enabled" {
  name = "${var.project_name}-root-mfa-enabled"

  source {
    owner             = "AWS"
    source_identifier = "ROOT_ACCOUNT_MFA_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder_status.main]

  tags = {
    Name        = "${var.project_name}-root-mfa-enabled"
    Environment = var.environment
    Compliance  = "CMMC"
    Project     = var.project_name
  }
}

resource "aws_config_config_rule" "iam_password_policy" {
  name = "${var.project_name}-iam-password-policy"

  source {
    owner             = "AWS"
    source_identifier = "IAM_PASSWORD_POLICY"
  }

  depends_on = [aws_config_configuration_recorder_status.main]

  tags = {
    Name        = "${var.project_name}-iam-password-policy"
    Environment = var.environment
    Compliance  = "CMMC"
    Project     = var.project_name
  }
}

# -----------------------------------------------------------------------------
# SNS topic for security / compliance alarms
# -----------------------------------------------------------------------------

resource "aws_sns_topic" "security_alerts" {
  name = "${var.project_name}-security-alerts"

  tags = {
    Name        = "${var.project_name}-security-alerts"
    Environment = var.environment
    Compliance  = "CMMC"
    Project     = var.project_name
  }
}

# -----------------------------------------------------------------------------
# CloudWatch metric filters + alarms (CloudTrail-based)
# -----------------------------------------------------------------------------

# Unauthorized API calls
resource "aws_cloudwatch_log_metric_filter" "unauthorized_api_calls" {
  name           = "${var.project_name}-unauthorized-api-calls"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name
  pattern        = "{ ($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\") }"

  metric_transformation {
    name          = "UnauthorizedAPICalls"
    namespace     = "CMMC/CloudTrail"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "unauthorized_api_calls" {
  alarm_name          = "${var.project_name}-unauthorized-api-calls"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "UnauthorizedAPICalls"
  namespace           = "CMMC/CloudTrail"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Unauthorized or AccessDenied API calls detected (CMMC AU/SI)"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]

  tags = {
    Name        = "${var.project_name}-unauthorized-api-calls"
    Environment = var.environment
    Compliance  = "CMMC"
    Project     = var.project_name
  }
}

# Root account usage
resource "aws_cloudwatch_log_metric_filter" "root_account_usage" {
  name           = "${var.project_name}-root-account-usage"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name
  pattern        = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" }"

  metric_transformation {
    name          = "RootAccountUsage"
    namespace     = "CMMC/CloudTrail"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "root_account_usage" {
  alarm_name          = "${var.project_name}-root-account-usage"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "RootAccountUsage"
  namespace           = "CMMC/CloudTrail"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Root account activity detected (CMMC AC/AU)"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]

  tags = {
    Name        = "${var.project_name}-root-account-usage"
    Environment = var.environment
    Compliance  = "CMMC"
    Project     = var.project_name
  }
}

# Console sign-in without MFA
resource "aws_cloudwatch_log_metric_filter" "console_signin_no_mfa" {
  name           = "${var.project_name}-console-signin-no-mfa"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name
  pattern        = "{ ($.eventName = \"ConsoleLogin\") && ($.additionalEventData.MFAUsed != \"Yes\") }"

  metric_transformation {
    name          = "ConsoleSignInWithoutMFA"
    namespace     = "CMMC/CloudTrail"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "console_signin_no_mfa" {
  alarm_name          = "${var.project_name}-console-signin-no-mfa"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ConsoleSignInWithoutMFA"
  namespace           = "CMMC/CloudTrail"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Console sign-in without MFA detected (CMMC IA/AC)"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]

  tags = {
    Name        = "${var.project_name}-console-signin-no-mfa"
    Environment = var.environment
    Compliance  = "CMMC"
    Project     = var.project_name
  }
}

# Security group changes
resource "aws_cloudwatch_log_metric_filter" "security_group_changes" {
  name           = "${var.project_name}-security-group-changes"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name
  pattern        = "{ ($.eventName = AuthorizeSecurityGroupIngress) || ($.eventName = AuthorizeSecurityGroupEgress) || ($.eventName = RevokeSecurityGroupIngress) || ($.eventName = RevokeSecurityGroupEgress) || ($.eventName = CreateSecurityGroup) || ($.eventName = DeleteSecurityGroup) }"

  metric_transformation {
    name          = "SecurityGroupChanges"
    namespace     = "CMMC/CloudTrail"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "security_group_changes" {
  alarm_name          = "${var.project_name}-security-group-changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "SecurityGroupChanges"
  namespace           = "CMMC/CloudTrail"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Security group configuration change detected (CMMC CM/SC)"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]

  tags = {
    Name        = "${var.project_name}-security-group-changes"
    Environment = var.environment
    Compliance  = "CMMC"
    Project     = var.project_name
  }
}

# Network ACL changes
resource "aws_cloudwatch_log_metric_filter" "nacl_changes" {
  name           = "${var.project_name}-nacl-changes"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name
  pattern        = "{ ($.eventName = CreateNetworkAcl) || ($.eventName = CreateNetworkAclEntry) || ($.eventName = DeleteNetworkAcl) || ($.eventName = DeleteNetworkAclEntry) || ($.eventName = ReplaceNetworkAclEntry) || ($.eventName = ReplaceNetworkAclAssociation) }"

  metric_transformation {
    name          = "NetworkAclChanges"
    namespace     = "CMMC/CloudTrail"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "nacl_changes" {
  alarm_name          = "${var.project_name}-nacl-changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "NetworkAclChanges"
  namespace           = "CMMC/CloudTrail"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Network ACL change detected (CMMC CM/SC)"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]

  tags = {
    Name        = "${var.project_name}-nacl-changes"
    Environment = var.environment
    Compliance  = "CMMC"
    Project     = var.project_name
  }
}
