# ------------------------------------------------------------------
# variables.tf — all input variables for the ETL pipeline infrastructure
# Defining variables here means you can reuse this Terraform config
# across different environments (dev, staging, prod) by just changing
# the .tfvars file — the resource definitions never need to change
# ------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region to deploy all resources into"
  type        = string
  default     = "us-east-1"   # North virginia — change to your preferred region
}

variable "project_name" {
  description = "Used as a prefix on all resource names for easy identification"
  type        = string
  default     = "etl-pipeline"
}

# --- VPC ---
variable "vpc_cidr" {
  description = "CIDR block for the VPC — defines the private IP range"
  type        = string
  default     = "10.0.0.0/16" 
}

# --- Subnets ---
variable "private_subnet_1_cidr" {
  description = "CIDR for private subnet 1 — RDS primary lives here"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_2_cidr" {
  description = "CIDR for private subnet 2 — required for RDS subnet group"
  type        = string
  default     = "10.0.2.0/24"
}

variable "public_subnet_cidr" {
  description = "CIDR for public subnet — future Lambda and bastion access"
  type        = string
  default     = "10.0.3.0/24"
}

# --- Availability Zones ---
variable "az_1" {
  description = "First availability zone"
  type        = string
  default     = "us-east-1a"
}

variable "az_2" {
  description = "Second availability zone"
  type        = string
  default     = "us-east-1b"
}

# --- Security ---
variable "my_ip_cidr" {
  description = "Your public IP in CIDR notation — only this IP can reach port 3306"
  type        = string
}

# --- RDS ---
variable "db_name" {
  description = "Name of the MySQL database to create inside the RDS instance"
  type        = string
  default     = "etl_pipeline"
}

variable "db_username" {
  description = "Master username for the RDS instance"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Master password for the RDS instance — stored in tfvars, never hardcoded"
  type        = string
  sensitive   = true   # Terraform will never print this value in logs
}

variable "db_instance_class" {
  description = "RDS instance type — db.t3.micro is free tier eligible"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Storage in GB — 20 is the free tier maximum"
  type        = number
  default     = 20
}