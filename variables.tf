
variable "ecs_launch_type" {
  type        = string
  default     = "FARGATE"
  description = "ECS launch type"

}

variable "container_essential" {
  type        = bool
  description = "Determines whether all other containers in a task are stopped."
}

variable "container_environment" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "The environment variables to pass to the container. This is a list of maps"
}

variable "container_readonly_root_filesystem" {
  type        = bool
  description = "Determines whether a container is given read-only access to its root filesystem. Due to how Terraform type casts booleans in json it is required to double quote this value"
}

variable "network_mode" {
  type        = string
  description = "The network mode to use for the task."
}


variable "cloudwatch_log_retention" {
  type        = number
  default     = 30
  description = "Cloudwatch log retention period in days"
}

variable "enable_container_insight" {
  description = "Control if we have to enable container insight or no "
  type        = string

}


variable "network_mode" {
  type        = string
  description = "The network mode to use for the task."
}

variable "deployment_controller_type" {
  type        = string
  description = "Type of deployment controller. Valid values are `CODE_DEPLOY` and `ECS`"
}

variable "deployment_maximum_percent" {
  type        = number
  description = "The upper limit of the number of tasks (as a percentage of `desired_count`) that can be running in a service during a deployment"
}

variable "deployment_minimum_healthy_percent" {
  type        = number
  description = "The lower limit (as a percentage of `desired_count`) of the number of tasks that must remain running and healthy in a service during a deployment"
}

variable "ignore_changes_task_definition" {
  type        = bool
  description = "Whether to ignore changes in container definition and task definition in the ECS service"
}

variable "propagate_tags" {
  type        = string
  description = "Specifies whether to propagate the tags from the task definition or the service to the tasks. The valid values are SERVICE and TASK_DEFINITION"
}

variable "ecs_service_enabled" {
  type        = bool
  description = "Whether or not to create the aws_ecs_service resource"
  default     = true
}


variable "manticore_be_service_ecs_target" {
  type = object({
    service_name     = string
    desired_count    = number
    min_count        = number
    max_count        = number
    task_memory      = number
    task_cpu         = number
    assign_public_ip = bool
    container_port   = number
    domain           = string
  })
}