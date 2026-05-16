# ==============================================================
# s3.tf — S3 bucket for the ETL data lake
# Stores raw CSV files and transformed Parquet files
# ==============================================================

variable "project_name" {
  description = "Name of the project used to construct resource names"
  type        = string
}

variable "aws_region" {
  description = "AWS region used for the S3 VPC endpoint service name"
  type        = string
}

resource "aws_s3_bucket" "data_lake" {
  bucket = "${var.project_name}-data-lake-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name    = "${var.project_name}-data-lake"
    Project = var.project_name
  }
}

# Block all public access — only Lambda and your IAM user can access this
resource "aws_s3_bucket_public_access_block" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versioning — keeps previous versions of files if they get overwritten
# Useful for debugging if a bad transform overwrites your Parquet
resource "aws_s3_bucket_versioning" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ==============================================================
# VPC GATEWAY ENDPOINT FOR S3
# Allows Lambda (inside your VPC) to reach S3 without going
# through the public internet — traffic stays within AWS network.
# no NAT gateway needed.
# ==============================================================

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.public.id]

  tags = {
    Name    = "${var.project_name}-s3-endpoint"
    Project = var.project_name
  }
}

# Data source — gets your AWS account ID dynamically
# Used to make the S3 bucket name globally unique
data "aws_caller_identity" "current" {}