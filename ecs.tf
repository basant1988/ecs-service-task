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

# LOG GROUP
resource "aws_cloudwatch_log_group" "manticore_be_service_loggroup" {
  name              = "${var.manticore_be_service_config["service_name"]}-loggroup"
  retention_in_days = var.cloudwatch_log_retention
  tags              = var.tag 
}



module "manticore_be_service_container_definition" {
  source  = "cloudposse/ecs-container-definition/aws"
  version = "0.58.1"
  container_name               = "${local.projectname}-be-service"
  container_image              = "mcr.microsoft.com/dotnet/samples:aspnetapp"
  essential                    = var.container_essential
  readonly_root_filesystem     = var.container_readonly_root_filesystem
  environment                  = var.container_environment
  port_mappings                = [
                                  {
                                    containerPort = var.manticore_be_service_config["container_port"]
                                    hostPort      = var.manticore_be_service_config["container_port"]
                                    protocol      = "tcp"
                                  }]
  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.manticore_be_service_loggroup.name
      awslogs-region        = var.region
      awslogs-stream-prefix = "${local.projectname}-be-service"
    }
  }
}


module "manticore_be_service_service_task" {
  source                             = "./modules/ecs-service-task"
  alb_security_group                 = aws_security_group.alb_sg.id
  container_definition_json          = module.manticore_be_service_container_definition.json_map_encoded_list
  ecs_cluster_arn                    = module.ecs_cluster.cluster_arn
  launch_type                        = var.ecs_launch_type
  vpc_id                             = var.vpc_id
  task_exec_role_arn                 = aws_iam_role.task_execution_role.arn
  task_role_arn                      = aws_iam_role.task_execution_role.arn
  security_group_ids                 = [aws_security_group.ecs_task_sg.id]
  subnet_ids                         = var.public_subnet_ids
  ignore_changes_task_definition     = var.ignore_changes_task_definition
  network_mode                       = var.network_mode
  propagate_tags                     = var.propagate_tags
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_controller_type         = var.deployment_controller_type

  assign_public_ip = var.manticore_be_service_config["assign_public_ip"]
  desired_count    = var.manticore_be_service_config["desired_count"]
  task_memory      = var.manticore_be_service_config["task_memory"]
  task_cpu         = var.manticore_be_service_config["task_cpu"]
  service_name     = var.manticore_be_service_config["service_name"]
  task_family      = var.manticore_be_service_config["service_name"]
  ecs_load_balancers = [
    {
      container_name   = var.manticore_be_service_config["service_name"]
      container_port   = var.manticore_be_service_config["container_port"]
      target_group_arn = aws_lb_target_group.merchant_service_tg.arn
      elb_name         = null
    }
  ]
  tags = var.tags
}

##################################################
#### Auto scaling policy for merchant-service ####
##################################################

resource "aws_appautoscaling_target" "manticore_be_service_ecs_target" {
  max_capacity       = var.manticore_be_service_config["max_count"]
  min_capacity       = var.manticore_be_service_config["min_count"]
  resource_id        = "service/${module.jux_ecs_cluster.cluster_name}/${module.manticore_be_service_service_task.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "manticore_be_service_ecs_policy_cpu" {
  name               = "${var.manticore_be_service_config["service_name"]}-cpu-autoscaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.manticore_be_service_ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.manticore_be_service_ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.manticore_be_service_ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 60
  }
}

resource "aws_appautoscaling_policy" "manticore_be_service_ecs_policy_memory" {
  name               = "${var.manticore_be_service_config["service_name"]}-memory-autoscaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.manticore_be_service_ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.manticore_be_service_ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.manticore_be_service_ecs_target.service_namespace
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = 60
  }
}
