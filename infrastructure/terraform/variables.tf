variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "etl-pipeline"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_1_cidr" {
  description = "Public subnet 1 - AZ a"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  description = "Public subnet 2 - AZ b - satisfies RDS 2 AZ requirement"
  type        = string
  default     = "10.0.2.0/24"
}

variable "az_1" {
  type    = string
  default = "us-east-1a"
}

variable "az_2" {
  type    = string
  default = "us-east-1b"
}

variable "my_ip_cidr" {
  description = "Your public IP in CIDR notation - only this IP can reach port 3306"
  type        = string
}

variable "db_name" {
  type    = string
  default = "etl_pipeline"
}

variable "db_username" {
  type    = string
  default = "admin"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}