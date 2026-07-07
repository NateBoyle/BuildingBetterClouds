# Security Groups

# Public Bastion / Web Security Group
resource "aws_security_group" "public" {
  name        = "${var.project_name}-public-sg"
  description = "Security group for public bastion and web resources"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from anywhere (restrict in production)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-public-sg"
    Environment = var.environment
    Compliance  = "CMMC"
    Project     = var.project_name
  }
}

# Private Application / SageMaker Security Group
resource "aws_security_group" "private" {
  name        = "${var.project_name}-private-sg"
  description = "Security group for private resources (EC2, SageMaker)"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "SSH from Public SG"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public.id]
  }

  ingress {
    description     = "Allow traffic from public SG"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.public.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-private-sg"
    Environment = var.environment
    Compliance  = "CMMC"
    Project     = var.project_name
  }
}