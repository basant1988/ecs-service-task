output "cluster_arn" {
  value       = aws_ecs_cluster.ecs_cluster.arn
  description = "Cluster ARN"
}

output "cluster_name" {
  value       = aws_ecs_cluster.ecs_cluster.name
  description = "Cluster Name"
}

output "log_group" {
  value       = aws_cloudwatch_log_group.loggroup.name
  description = "Cluster log group name"
}

output "log_group_name" {
  value       = aws_cloudwatch_log_group.loggroup.arn
  description = "Cluster log group ARN"
}