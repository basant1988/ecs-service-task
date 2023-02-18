enable_container_insight = "enabled"
cloudwatch_log_retention = 30

ecs_launch_type = "FARGATE"
network_mode = "awsvpc"
ignore_changes_task_definition = true # Need to make it true once we are done with development
propagate_tags = "TASK_DEFINITION"
deployment_minimum_healthy_percent = 100
deployment_maximum_percent = 200
deployment_controller_type = "ECS"

container_essential = true
container_readonly_root_filesystem = false
container_environment = []

lb_listnerport = 443

manticore_be_service_config = {
  service_name        = "manticore-be-service"
  desired_count       = 1
  min_count           = 1
  max_count           = 1
  task_memory         = 512
  task_cpu            = 256
  assign_public_ip    = true
  container_port      = 3000
  domain              = "consumer-web.dev.juxapp.co.uk"
}