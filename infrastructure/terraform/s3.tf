# ==============================================================
# s3.tf — S3 bucket for the ETL data lake
# Stores raw CSV files and transformed Parquet files
# ==============================================================

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
resource "aws_s3_bucket_versioning" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ==============================================================
# VPC GATEWAY ENDPOINT FOR S3
# Allows Lambda inside the VPC to reach S3 without NAT gateway
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

# Gets your AWS account ID dynamically
# Makes the bucket name globally unique
data "aws_caller_identity" "current" {}