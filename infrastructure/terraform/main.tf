# ==============================================================
# main.tf — ETL Pipeline AWS Infrastructure
# Provisions: VPC, Subnets, IGW, Route Table, Security Group, RDS
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

# Configure the AWS provider
provider "aws" {
  region = var.aws_region
}

# ==============================================================
# VPC
# ==============================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true    # allows resources inside VPC to resolve DNS
  enable_dns_hostnames = true    # gives RDS a DNS hostname you can connect to

  tags = {
    Name    = "${var.project_name}-vpc"
    Project = var.project_name
  }
}

# ==============================================================
# SUBNETS
# Subnets are subdivisions of your VPC.
# Private subnets have no route to the internet — RDS sits here.
# Public subnet has internet access — for Lambda / future use.
# RDS requires a minimum of 2 subnets in different AZs for its
# subnet group, even on single-AZ free tier instances.
# ==============================================================

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_1_cidr
  availability_zone = var.az_1

  tags = {
    Name    = "${var.project_name}-private-subnet-1"
    Project = var.project_name
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_2_cidr
  availability_zone = var.az_2

  tags = {
    Name    = "${var.project_name}-private-subnet-2"
    Project = var.project_name
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.az_1
  map_public_ip_on_launch = true   # instances in this subnet get a public IP

  tags = {
    Name    = "${var.project_name}-public-subnet"
    Project = var.project_name
  }
}

# ==============================================================
# INTERNET GATEWAY
# Attaches your VPC to the internet.
# Without this, nothing in your VPC can reach the outside world
# and nothing outside can reach in — even through the public subnet.
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

# Associate the route table with the public subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ==============================================================
# SECURITY GROUP
# Inbound: only port 3306 (MySQL) from your IP — nothing else
# Outbound: all traffic allowed (standard for internal comms)
# ==============================================================

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Security group for ETL pipeline RDS MySQL instance"
  vpc_id      = aws_vpc.main.id

  # Inbound rule — MySQL port, your IP only
  ingress {
    description = "MySQL access from developer IP only"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  # Outbound rule — allow all outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-rds-sg"
    Project = var.project_name
  }
}

# ==============================================================
# DB SUBNET GROUP
# Tells RDS which subnets it's allowed to place itself into.
# ==============================================================

resource "aws_db_subnet_group" "main" {
  name        = "${var.project_name}-db-subnet-group"
  description = "Subnet group for ETL pipeline RDS which spans 2 private subnets"
  subnet_ids  = [
    aws_subnet.private_1.id,
    aws_subnet.private_2.id
  ]

  tags = {
    Name    = "${var.project_name}-db-subnet-group"
    Project = var.project_name
  }
}

# ==============================================================
# RDS MYSQL INSTANCE
# The actual database — provisioned inside the private subnet,
# protected by the security group, within your VPC.
#
# Key settings explained:
#   publicly_accessible = true  → needed so your laptop can connect
#                                 even though it's in a private subnet.
#                                 The security group still restricts
#                                 access to your IP only — this just
#                                 gives it a public DNS endpoint.
#   skip_final_snapshot = true  → on destroy, don't take a snapshot.
#                                 Fine for dev/portfolio — saves cost.
#   multi_az = false            → single AZ is free tier eligible.
#                                 Multi-AZ doubles cost.
# ==============================================================

resource "aws_db_instance" "main" {
  identifier        = "${var.project_name}-db"
  engine            = "mysql"
  engine_version    = "8.0.46"  # latest MySQL 8.0 version as of June 2024
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible = true    # security group limits access to your IP
  multi_az            = false   # single AZ — free tier
  skip_final_snapshot = true    # no snapshot on terraform destroy

  # Disable automated backups — saves on free tier storage
  backup_retention_period = 0

  tags = {
    Name    = "${var.project_name}-db"
    Project = var.project_name
  }
}