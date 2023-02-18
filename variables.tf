
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