output "workflow_arn" {
  description = "ARN del workflow de Glue"
  value       = aws_glue_workflow.fraud_detection.arn
}

output "workflow_name" {
  description = "Nombre del workflow de Glue"
  value       = aws_glue_workflow.fraud_detection.name
}

output "jobs" {
  description = "Información de los trabajos de Glue"
  value = {
    for key, job in aws_glue_job.jobs : key => {
      name = job.name
      arn  = job.arn
    }
  }
}

output "triggers" {
  description = "Información de los triggers de Glue"
  value = merge(
    {
      daily = {
        name = aws_glue_trigger.daily_trigger.name
        type = aws_glue_trigger.daily_trigger.type
      }
      weekly = {
        name = aws_glue_trigger.weekly_model_trigger.name
        type = aws_glue_trigger.weekly_model_trigger.type
      }
      model_evaluation = {
        name = aws_glue_trigger.model_evaluation_trigger.name
        type = aws_glue_trigger.model_evaluation_trigger.type
      }
    },
    {
      for key, trigger in aws_glue_trigger.conditional_triggers : key => {
        name = trigger.name
        type = trigger.type
      }
    }
  )
}

output "role_arn" {
  description = "ARN del rol IAM para Glue"
  value       = aws_iam_role.glue_role.arn
}

output "cloudwatch_alarms" {
  description = "Información de las alarmas de CloudWatch"
  value = {
    for key, alarm in aws_cloudwatch_metric_alarm.job_failure_alarms : key => {
      name      = alarm.alarm_name
      metric    = alarm.metric_name
      threshold = alarm.threshold
    }
  }
} 