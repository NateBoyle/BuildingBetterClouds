
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