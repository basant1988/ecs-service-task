resource "aws_cloudwatch_log_group" "loggroup" {
  name              = "${var.name_prefix}-ecs-loggroup"
  retention_in_days = var.cloudwatch_log_retention
  tags              = merge(var.tags, { Env = "${terraform.workspace}" })
}

# Create a cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.name_prefix}-cluster"
  setting {
    name  = "containerInsights"
    value = var.enable_container_insight
  }
  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      log_configuration {
        cloud_watch_encryption_enabled = false
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.loggroup.name
      }
    }
  }
  tags = merge(var.tags, { Env = "${terraform.workspace}" })
}

