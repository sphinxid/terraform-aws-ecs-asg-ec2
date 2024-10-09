output "task_definition_arn" {
  description = "The ARN of the task definition"
  value       = aws_ecs_task_definition.task.arn
}

output "service_name" {
  description = "The name of the ECS service"
  value       = aws_ecs_service.service.name
}

output "target_group_arn" {
  description = "The ARN of the target group"
  value       = aws_lb_target_group.target_group.arn
}

output "listener_rule_arn" {
  description = "The ARN of the listener rule"
  value       = aws_lb_listener_rule.listener_rule.arn
}