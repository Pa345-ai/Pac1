################################################################################
# AWS Terraform Starter Kit
# Copyright (c) 2025 RUWANPURAGE PAVITHRA PARAMI RANASINGHE
# Licensed for single commercial use - See LICENSE.txt
################################################################################

############################################
# KMS KEY FOR SECRETS
############################################

data "aws_iam_policy_document" "secrets_kms_policy" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "Allow ECS Task Execution Role to Decrypt Secrets"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.ecs_task_execution.arn]
    }

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "Allow Secrets Manager to Use Key"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["secretsmanager.amazonaws.com"]
    }

    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:CreateGrant"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.${var.aws_region}.amazonaws.com"]
    }
  }
}

resource "aws_kms_key" "secrets" {
  description             = "KMS key for application secrets"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.secrets_kms_policy.json

  tags = {
    Name = "${var.project_name}-${var.environment}-secrets-kms"
  }
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${var.project_name}-${var.environment}-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}

############################################
# SECRETSMANAGER SECRET
############################################

resource "aws_secretsmanager_secret" "app_secrets" {
  name                    = "${var.project_name}-${var.environment}-app-secrets"
  recovery_window_in_days = 7
  kms_key_id              = aws_kms_key.secrets.arn

  tags = {
    Name        = "${var.project_name}-${var.environment}-app-secrets"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "app_secrets" {
  secret_id = aws_secretsmanager_secret.app_secrets.id

  secret_string = jsonencode({
    STRIPE_SECRET_KEY = "sk_test_placeholder"
    OPENAI_API_KEY    = "sk-placeholder"
    JWT_SECRET        = "placeholder_string"
    DATABASE_URL      = "postgres://user:pass@host:5432/db"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

############################################
# IAM POLICY DOCUMENT FOR SECRET ACCESS
# (Used by iam.tf for the execution role)
############################################

data "aws_iam_policy_document" "secrets_access" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [aws_secretsmanager_secret.app_secrets.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
    resources = [aws_kms_key.secrets.arn]
  }
}
