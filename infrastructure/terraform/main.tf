# ==============================================================
# main.tf — ETL Pipeline AWS Infrastructure (Simplified)
# 2 public subnets across 2 AZs — satisfies RDS requirement
# Security group restricts access to your IP only
# ==============================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "aws" {
  region = var.aws_region
}

# ==============================================================
# VPC
# Your isolated private network in AWS
# ==============================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "${var.project_name}-vpc"
    Project = var.project_name
  }
}

# ==============================================================
# PUBLIC SUBNETS — one in each AZ
# Both are public so RDS gets a reachable endpoint
# Security group is what restricts who can actually connect
# ==============================================================

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = var.az_1
  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.project_name}-public-subnet-1"
    Project = var.project_name
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = var.az_2
  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.project_name}-public-subnet-2"
    Project = var.project_name
  }
}

# ==============================================================
# INTERNET GATEWAY
# Connects your VPC to the internet
# Without this, nothing in your subnets is reachable externally
# ==============================================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${var.project_name}-igw"
    Project = var.project_name
  }
}

# ==============================================================
# ROUTE TABLE
# Associated with both public subnets
# ==============================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name    = "${var.project_name}-public-rt"
    Project = var.project_name
  }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# ==============================================================
# SECURITY GROUP
# Port 3306 open to your IP only — everything else blocked
# ==============================================================

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Security group for ETL pipeline RDS MySQL instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "MySQL access from developer IP only"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-rds-sg"
    Project = var.project_name
  }
}

# ==============================================================
# DB SUBNET GROUP
# Spans both public subnets across 2 AZs
# ==============================================================

resource "aws_db_subnet_group" "main" {
  name        = "${var.project_name}-db-subnet-group"
  description = "Subnet group for ETL pipeline RDS - spans 2 public subnets across 2 AZs"
  subnet_ids  = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]

  tags = {
    Name    = "${var.project_name}-db-subnet-group"
    Project = var.project_name
  }
}

# ==============================================================
# RDS MYSQL INSTANCE
# Sits in the public subnet group
# Accessible only from your IP via the security group
# ==============================================================

resource "aws_db_instance" "main" {
  identifier        = "${var.project_name}-db"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible     = true
  multi_az                = false
  skip_final_snapshot     = true
  backup_retention_period = 0

  tags = {
    Name    = "${var.project_name}-db"
    Project = var.project_name
  }
}