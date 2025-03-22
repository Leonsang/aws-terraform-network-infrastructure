output "asg_name" {
  description = "Nombre del Auto Scaling Group"
  value       = aws_autoscaling_group.main.name
}

output "asg_arn" {
  description = "ARN del Auto Scaling Group"
  value       = aws_autoscaling_group.main.arn
}

output "launch_template_id" {
  description = "ID del Launch Template"
  value       = aws_launch_template.main.id
}

output "launch_template_latest_version" {
  description = "Última versión del Launch Template"
  value       = aws_launch_template.main.latest_version
}

output "instance_role_name" {
  description = "Nombre del rol IAM para las instancias"
  value       = aws_iam_role.instance.name
}

output "instance_role_arn" {
  description = "ARN del rol IAM para las instancias"
  value       = aws_iam_role.instance.arn
}

output "instance_profile_name" {
  description = "Nombre del perfil de instancia"
  value       = aws_iam_instance_profile.main.name
}

output "instance_profile_arn" {
  description = "ARN del perfil de instancia"
  value       = aws_iam_instance_profile.main.arn
}

output "cpu_high_alarm_arn" {
  description = "ARN de la alarma de CPU alto"
  value       = aws_cloudwatch_metric_alarm.cpu_high.arn
}

output "memory_high_alarm_arn" {
  description = "ARN de la alarma de memoria alta"
  value       = aws_cloudwatch_metric_alarm.memory_high.arn
}

output "scaling_dashboard_name" {
  description = "Nombre del dashboard de CloudWatch para escalado"
  value       = aws_cloudwatch_dashboard.scaling.dashboard_name
} 