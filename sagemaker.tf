# sagemaker.tf

# IAM Execution Role (shared)
resource "aws_iam_role" "sagemaker_execution" {
  name = "${var.project_name}-sagemaker-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "sagemaker.amazonaws.com" }
    }]
  })

  tags = {
    Name        = "${var.project_name}-sagemaker-role"
    Environment = var.environment
    Compliance  = "CMMC"
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "sagemaker_basic" {
  role       = aws_iam_role.sagemaker_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

# Domain 1: Custom Models
resource "aws_sagemaker_domain" "custom_models" {
  domain_name = "${var.project_name}-custom-models"
  auth_mode   = "IAM"
  vpc_id      = aws_vpc.main.id
  subnet_ids  = aws_subnet.private[*].id

  default_user_settings {
    execution_role  = aws_iam_role.sagemaker_execution.arn
    security_groups = [aws_security_group.private.id]
  }

  tags = {
    Name        = "${var.project_name}-custom-models-domain"
    Purpose     = "Custom-Models"
    Environment = var.environment
    Compliance  = "CMMC"
  }
}

# Domain 2: Pre-built / Marketplace Models
resource "aws_sagemaker_domain" "prebuilt_models" {
  domain_name = "${var.project_name}-prebuilt-models"
  auth_mode   = "IAM"
  vpc_id      = aws_vpc.main.id
  subnet_ids  = aws_subnet.private[*].id

  default_user_settings {
    execution_role  = aws_iam_role.sagemaker_execution.arn
    security_groups = [aws_security_group.private.id]
  }

  tags = {
    Name        = "${var.project_name}-prebuilt-models-domain"
    Purpose     = "Pre-built-Models"
    Environment = var.environment
    Compliance  = "CMMC"
  }
}