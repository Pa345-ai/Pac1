############################################
# KMS KEY FOR SECRETS
############################################

resource "aws_kms_key" "secrets" {
  description             = "KMS key for application secrets"
  deletion_window_in_days = 7
  enable_key_rotation     = true
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
############################################

data "aws_iam_policy_document" "secrets_access" {
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = [aws_secretsmanager_secret.app_secrets.arn]
  }
}

