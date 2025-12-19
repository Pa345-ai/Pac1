############################################
# ECS TASK ASSUME ROLE
############################################
data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution" {
  name               = "${var.project_name}-${var.environment}-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

############################################
# ECS EXECUTION SECRETS POLICY
############################################
data "aws_iam_policy_document" "ecs_execution_secrets" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "kms:Decrypt"
    ]
    resources = [aws_secretsmanager_secret.app_secrets.arn]
  }
}

resource "aws_iam_role_policy" "ecs_execution_secrets" {
  name   = "${var.project_name}-${var.environment}-secrets-execution-policy"
  role   = aws_iam_role.ecs_task_execution.id
  policy = data.aws_iam_policy_document.ecs_execution_secrets.json
}

############################################
# ECS TASK ROLE
############################################
resource "aws_iam_role" "ecs_task" {
  name               = "${var.project_name}-${var.environment}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

############################################
# ECS TASK LOGS POLICY (tfsec-compliant)
############################################
data "aws_iam_policy_document" "ecs_task_logs" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    # tfsec-compliant: only attach to a specific log group and its streams
    resources = [
      "${aws_cloudwatch_log_group.ecs.arn}/ecs" # exact log group stream prefix
    ]
  }
}

resource "aws_iam_role_policy" "ecs_task_logs" {
  name   = "${var.project_name}-${var.environment}-task-logs-policy"
  role   = aws_iam_role.ecs_task.id
  policy = data.aws_iam_policy_document.ecs_task_logs.json
}

