################################################################################
# AWS Terraform Starter Kit
# Copyright (c) 2025 RUWANPURAGE PAVITHRA PARAMI RANASINGHE
# Licensed for single commercial use - See LICENSE.txt
################################################################################

############################################
# DATA SOURCES
############################################

data "aws_availability_zones" "available" {
  state = "available"
}

############################################
# VPC
############################################

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

############################################
# INTERNET GATEWAY
############################################

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

############################################
# PUBLIC SUBNETS
############################################

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-${var.environment}-public-${count.index + 1}"
    Type = "Public"
  }
}

############################################
# PRIVATE SUBNETS
############################################

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 11)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-${var.environment}-private-${count.index + 1}"
    Type = "Private"
  }
}

############################################
# ELASTIC IP FOR NAT GATEWAY
############################################

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-eip"
  }

  depends_on = [aws_internet_gateway.main]
}

############################################
# NAT GATEWAY
############################################

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.project_name}-${var.environment}-nat"
  }

  depends_on = [aws_internet_gateway.main]
}

############################################
# PUBLIC ROUTE TABLE
############################################

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-public-rt"
  }
}

############################################
# PRIVATE ROUTE TABLE
############################################

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-private-rt"
  }
}

############################################
# ROUTE TABLE ASSOCIATIONS
############################################

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

############################################
# VPC FLOW LOGS - CloudWatch Log Group
############################################

resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name              = "/aws/vpc-flow-logs/${var.project_name}-${var.environment}"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.cloudwatch.arn

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc-flow-logs"
  }
}

############################################
# VPC FLOW LOGS - Flow Log Resource
############################################

resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.vpc_flow_log.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-flow-log"
  }
}

############################################
# IAM ROLE FOR VPC FLOW LOGS
############################################

resource "aws_iam_role" "vpc_flow_log" {
  name = "${var.project_name}-${var.environment}-vpc-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc-flow-log-role"
  }
}

############################################
# IAM POLICY FOR VPC FLOW LOGS
# Note: Wildcards are required for VPC Flow Logs
############################################
# tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "vpc_flow_logs" {
  # Statement 1: Allow creating log streams in the specific log group
  statement {
    sid    = "AllowCreateLogStream"
    effect = "Allow"

    actions = [
      "logs:CreateLogStream"
    ]

    resources = [
      aws_cloudwatch_log_group.vpc_flow_log.arn
    ]
  }

  # Statement 2: Allow writing log events to any stream in this log group
  # Wildcard required: AWS VPC Flow Logs dynamically create stream names based on ENI IDs
  # Example stream names: eni-0a1b2c3d4e5f6g7h8, eni-9i8h7g6f5e4d3c2b1
  # This is scoped to the specific log group ARN for security
  statement {
    sid    = "AllowPutLogEvents"
    effect = "Allow"

    actions = [
      "logs:PutLogEvents"
    ]

    resources = [
      "${aws_cloudwatch_log_group.vpc_flow_log.arn}:log-stream:*"
    ]
  }

  # Statement 3: Allow describing log groups and streams (read-only)
  statement {
    sid    = "AllowDescribeLogResources"
    effect = "Allow"

    actions = [
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]

    resources = [
      aws_cloudwatch_log_group.vpc_flow_log.arn
    ]
  }

  # Statement 4: Allow KMS operations for encrypted CloudWatch Logs
  statement {
    sid    = "AllowKMSOperations"
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]

    resources = [
      aws_kms_key.cloudwatch.arn
    ]
  }
}

resource "aws_iam_role_policy" "vpc_flow_log" {
  name   = "${var.project_name}-${var.environment}-vpc-flow-log-policy"
  role   = aws_iam_role.vpc_flow_log.id
  policy = data.aws_iam_policy_document.vpc_flow_logs.json
}
