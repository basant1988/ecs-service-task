resource "aws_ecr_repository" "backend_ecr_repo" {
  count                = var.environment == "dev" ? 1 : 0
  provider             = aws.toolsaccount
  name                 = "${var.projectname}-backend"
  image_tag_mutability = "MUTABLE"
  tags                 = var.tags
}

data "aws_iam_policy_document" "backend_ecr_repo_policy_doc" {
  count    = var.environment == "dev" ? 1 : 0
  provider = aws.toolsaccount
  # Read
  statement {
    sid = "ECRRead"

    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetAuthorizationToken",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
    ]

    principals {
      identifiers = []
      type        = "AWS"
    }
  }
  # Read and Write
  statement {
    sid = "ECRWrite"

    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
    ]

    principals {
      identifiers = []
      type        = "AWS"
    }
  }
}

resource "aws_ecr_repository_policy" "backend_ecr_repo_policy" {
  count      = var.environment == "dev" ? 1 : 0
  provider   = aws.toolsaccount
  repository = aws_ecr_repository.backend_ecr_repo[0].name
  policy     = data.aws_iam_policy_document.backend_ecr_repo_policy_doc[0].json
}


module "ecs_cluster" {
  source                   = "./modules/ecs-cluster"
  name_prefix              = "${var.projectname}-cluster"
  cloudwatch_log_retention = var.cloudwatch_log_retention
  enable_container_insight = var.enable_container_insight
  tags                     = var.tags
}

resource "aws_security_group" "alb_sg" {
  name   = "${local.projectname}-albsg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 443
    protocol    = "tcp"
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.tags, { Name = "${local.projectname}-albsg" })
}

resource "aws_security_group" "ecs_task_sg" {
  name   = "${local.projectname}-ecs-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 0
    protocol        = "tcp"
    to_port         = 65535
    security_groups = ["${aws_security_group.alb_sg.id}"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}
