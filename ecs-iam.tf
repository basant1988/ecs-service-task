# IAM policy document to be assumed by ecs task
data "aws_iam_policy_document" "task_execution_assume_role_policy" {
  statement {
    sid     = "AllowAssumeByEcsTasks"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# IAM policy document for execution role
data "aws_iam_policy_document" "task_execution_role_policy" {
  statement {
    sid    = "AllowECRPull"
    effect = "Allow"

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowECRAuth"
    effect = "Allow"

    actions = ["ecr:GetAuthorizationToken"]

    resources = ["*"]
  }

  statement {
    sid    = "AllowLogging"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowSSMParameterFetch"
    effect = "Allow"

    actions = [
      "ssm:GetParameters",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]

    resources = ["*"]
  }


  statement {
    sid    = "AllowS3Access"
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowSecretManagerAndSSM"
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
      "kms:Decrypt"
    ]

    resources = ["*"]
  }
}

# Task Execution IAM role
resource "aws_iam_role" "task_execution_role" {
  name               = "${var.projectname}-exec-role"
  assume_role_policy = data.aws_iam_policy_document.task_execution_assume_role_policy.json
}

# Execution iam role poilicy
resource "aws_iam_role_policy" "execution_role" {
  role   = aws_iam_role.task_execution_role.name
  policy = data.aws_iam_policy_document.task_execution_role_policy.json
}

############################################
############ Codebuild Role ################
############################################

data "aws_iam_policy_document" "code_build_be_policy_document" {
  count = var.enabled ? 1 : 0

  statement {
    sid = ""

    actions = [
      "codecommit:GitPull",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:GetAuthorizationToken",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecs:RunTask",
      "iam:PassRole",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "ssm:GetParameters",
      "secretsmanager:GetSecretValue",
    ]

    effect = "Allow"

    resources = [
      "*",
    ]
  }

}
