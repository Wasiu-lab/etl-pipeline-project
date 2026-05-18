output "rds_endpoint" {
  description = "RDS endpoint - paste into .env as DB_HOST"
  value       = aws_db_instance.main.address
}

output "rds_port" {
  value = aws_db_instance.main.port
}

output "rds_db_name" {
  value = aws_db_instance.main.db_name
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_1_id" {
  value = aws_subnet.public_1.id
}

output "public_subnet_2_id" {
  value = aws_subnet.public_2.id
}

output "rds_security_group_id" {
  value = aws_security_group.rds.id
}

output "s3_bucket_name" {
  description = "S3 data lake bucket name - use this to upload your CSV"
  value       = aws_s3_bucket.data_lake.bucket
}

# output "lambda_function_name" {
#   description = "Lambda function name - use this to invoke manually"
#   value       = aws_lambda_function.etl_pipeline.function_name
# }

# output "eventbridge_schedule" {
#   description = "EventBridge schedule expression"
#   value       = aws_cloudwatch_event_rule.pipeline_schedule.schedule_expression
# }