
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

output "cloudtrail_name" {
  value = aws_cloudtrail.main.name
}

output "config_recorder_name" {
  value = aws_config_configuration_recorder.main.name
}

output "security_alerts_topic_arn" {
  value = aws_sns_topic.security_alerts.arn
}