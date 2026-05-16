# ==============================================================
# lambda.tf — Lambda function + EventBridge schedule
# ==============================================================

# ------------------------------------------------------------------
# Lambda Security Group
# Controls what traffic Lambda can send and receive.
# Lambda only needs outbound access — to S3 (via VPC endpoint)
# and to RDS (port 3306 within the VPC).
# ------------------------------------------------------------------

resource "aws_security_group" "lambda" {
  name        = "${var.project_name}-lambda-sg"
  description = "Security group for ETL pipeline Lambda function"
  vpc_id      = aws_vpc.main.id

  # Allow Lambda to connect to RDS on port 3306
  egress {
    description     = "MySQL access to RDS"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.rds.id]
  }

  # Allow Lambda to reach S3 via the VPC Gateway Endpoint
  egress {
    description = "HTTPS for S3 VPC endpoint"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-lambda-sg"
    Project = var.project_name
  }
}

# ------------------------------------------------------------------
# Update RDS Security Group to accept traffic from Lambda
# Lambda's security group is the source — only Lambda can reach RDS
# ------------------------------------------------------------------

resource "aws_security_group_rule" "rds_from_lambda" {
  type                     = "ingress"
  description              = "Allow Lambda to connect to RDS on port 3306"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = aws_security_group.lambda.id
}

# # ------------------------------------------------------------------
# # Lambda Function
# # The deployment package (zip) is created by deploy.ps1 and
# # uploaded to S3 before Terraform runs.
# # ------------------------------------------------------------------

# resource "aws_lambda_function" "etl_pipeline" {
#   function_name = "${var.project_name}-function"
#   role          = aws_iam_role.lambda_exec.arn

#   # Package uploaded to S3 by deploy.ps1
#   s3_bucket = aws_s3_bucket.data_lake.bucket
#   s3_key    = "lambda/deployment_package.zip"

#   # handler = "filename.function_name" inside your zip
#   handler = "lambda_handler.lambda_handler"
#   runtime = "python3.11"

#   # 15 minutes — maximum Lambda allows
#   # 300k row pipeline needs the full window
#   timeout = 900

#   # 1024MB gives Lambda more CPU allocation — speeds up pandas operations
#   memory_size = 1024

#   # Run Lambda inside your VPC so it can reach RDS directly
#   vpc_config {
#     subnet_ids         = [aws_subnet.public_1.id, aws_subnet.public_2.id]
#     security_group_ids = [aws_security_group.lambda.id]
#   }

#   # Environment variables — Lambda reads these instead of .env file
#   # These replace your local .env when running in the cloud
#   environment {
#     variables = {
#       DB_HOST          = aws_db_instance.main.address
#       DB_PORT          = "3306"
#       DB_NAME          = var.db_name
#       DB_USER          = var.db_username
#       DB_PASSWORD      = var.db_password
#       RAW_FILE_PATH    = "s3://${aws_s3_bucket.data_lake.bucket}/raw/chicago_Food_Inspections.csv"
#       PARQUET_FILE_PATH = "s3://${aws_s3_bucket.data_lake.bucket}/parquet/chicago_food_inspections_clean.parquet"
#     }
#   }

#   tags = {
#     Name    = "${var.project_name}-function"
#     Project = var.project_name
#   }

#   # Terraform must wait for the deployment package to exist in S3
#   depends_on = [aws_iam_role_policy_attachment.lambda_logs]
# }

# # ------------------------------------------------------------------
# # EventBridge Rule — the schedule
# # cron(minutes hours day month day-of-week year)
# # cron(0 6 * * ? *) = every day at 6:00 AM UTC
# # ------------------------------------------------------------------

# resource "aws_cloudwatch_event_rule" "pipeline_schedule" {
#   name                = "${var.project_name}-schedule"
#   description         = "Triggers ETL pipeline Lambda on a daily schedule"
#   schedule_expression = var.schedule_expression

#   tags = {
#     Name    = "${var.project_name}-schedule"
#     Project = var.project_name
#   }
# }

# # Target — which Lambda to trigger when the rule fires
# resource "aws_cloudwatch_event_target" "lambda_target" {
#   rule      = aws_cloudwatch_event_rule.pipeline_schedule.name
#   target_id = "ETLPipelineLambda"
#   arn       = aws_lambda_function.etl_pipeline.arn
# }

# # Permission — allows EventBridge to actually invoke the Lambda
# resource "aws_lambda_permission" "allow_eventbridge" {
#   statement_id  = "AllowExecutionFromEventBridge"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.etl_pipeline.function_name
#   principal     = "events.amazonaws.com"
#   source_arn    = aws_cloudwatch_event_rule.pipeline_schedule.arn
# }