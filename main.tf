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

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = "building-better-clouds-key"
}