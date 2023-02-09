
variable "name_prefix" {
  type        = string
  description = "Name prefix to be attached in all resources"
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


variable "tags" {
  type    = map(any)
  default = {}
}