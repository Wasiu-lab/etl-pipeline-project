# ==============================================================
# iam.tf — IAM role and policies for Lambda
#
# Lambda needs permission to:
#   1. Execute inside a VPC (create network interfaces)
#   2. Write logs to CloudWatch (so you can debug runs)
#   3. Read and write to your S3 bucket
#   4. Connect to RDS (RDS access is handled by the security group,
#      not IAM — no RDS policy needed here)
# ==============================================================

# The IAM role — defines who can assume it
# Lambda service is granted permission to assume this role
resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name    = "${var.project_name}-lambda-role"
    Project = var.project_name
  }
}

# Policy 1: VPC execution — Lambda needs this to run inside a VPC
# Without this, Lambda can't create the network interfaces it needs
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Policy 2: CloudWatch logs — so you can see Lambda output and debug errors
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Policy 3: S3 access — read raw CSV, write Parquet
# Scoped to your specific bucket only — least privilege principle
resource "aws_iam_policy" "lambda_s3" {
  name        = "${var.project_name}-lambda-s3-policy"
  description = "Allows Lambda to read and write to the ETL data lake bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",     # read CSV files
          "s3:PutObject",     # write Parquet files
          "s3:DeleteObject",  # clean up old files if needed
          "s3:ListBucket"     # list bucket contents
        ]
        Resource = [
          aws_s3_bucket.data_lake.arn,
          "${aws_s3_bucket.data_lake.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_s3_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_s3.arn
}