resource "aws_secretsmanager_secret" "app_secrets" {
  name                    = "${var.project_name}-${var.environment}-app-secrets"
  recovery_window_in_days = 7
  # tfsec:ignore:aws-ssm-secret-use-customer-key
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

data "aws_iam_policy_document" "secrets_access" {
  statement {
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = [aws_secretsmanager_secret.app_secrets.arn]
  }
}

