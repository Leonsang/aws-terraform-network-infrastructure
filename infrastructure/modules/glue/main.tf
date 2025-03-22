locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# Rol IAM para Glue
resource "aws_iam_role" "glue_role" {
  name = "${local.name_prefix}-glue-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Políticas IAM
resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_access" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

# Scripts en S3
resource "aws_s3_object" "glue_scripts" {
  for_each = {
    data_overview      = "notebooks/exploratory/01_data_overview.json"
    temporal_analysis  = "notebooks/exploratory/02_temporal_analysis.json"
    feature_engineering = "notebooks/feature_engineering/01_feature_engineering.json"
    model_training     = "notebooks/modeling/01_model_training.json"
    text_analysis      = "notebooks/unstructured_data/01_text_analysis.json"
    model_evaluation   = "notebooks/evaluation/01_model_evaluation.json"
  }

  bucket = var.scripts_bucket_id
  key    = "scripts/${each.key}.py"
  source = each.value
  etag   = filemd5(each.value)
}

# Trabajos de Glue
resource "aws_glue_job" "jobs" {
  for_each = aws_s3_object.glue_scripts

  name     = "${local.name_prefix}-${each.key}"
  role_arn = aws_iam_role.glue_role.arn

  command {
    script_location = "s3://${var.scripts_bucket_id}/scripts/${each.key}.py"
    python_version  = var.glue_python_version
  }

  default_arguments = merge(var.default_arguments, {
    "--job-language" = "python"
    "--BUCKET"       = var.data_bucket_id
    "--PREFIX"       = var.project_name
    "--ENVIRONMENT"  = var.environment
  })

  glue_version      = var.glue_version
  worker_type       = var.worker_type
  number_of_workers = var.number_of_workers
  timeout           = var.job_timeout

  tags = var.tags
}

# Workflow
resource "aws_glue_workflow" "fraud_detection" {
  name = "${local.name_prefix}-workflow"
  tags = var.tags
}

# Triggers
resource "aws_glue_trigger" "daily_trigger" {
  name          = "${local.name_prefix}-daily-trigger"
  type          = "SCHEDULED"
  workflow_name = aws_glue_workflow.fraud_detection.name
  schedule      = "cron(0 0 * * ? *)"

  actions {
    job_name = aws_glue_job.jobs["data_overview"].name
  }

  tags = var.tags
}

resource "aws_glue_trigger" "conditional_triggers" {
  for_each = {
    temporal_analysis = {
      predecessor = "data_overview"
    }
    feature_engineering = {
      predecessor = "temporal_analysis"
    }
    text_analysis = {
      predecessor = "feature_engineering"
    }
  }

  name          = "${local.name_prefix}-${each.key}-trigger"
  type          = "CONDITIONAL"
  workflow_name = aws_glue_workflow.fraud_detection.name

  predicate {
    conditions {
      job_name = aws_glue_job.jobs[each.value.predecessor].name
      state    = "SUCCEEDED"
    }
  }

  actions {
    job_name = aws_glue_job.jobs[each.key].name
  }

  tags = var.tags
}

resource "aws_glue_trigger" "weekly_model_trigger" {
  name          = "${local.name_prefix}-weekly-model-trigger"
  type          = "SCHEDULED"
  workflow_name = aws_glue_workflow.fraud_detection.name
  schedule      = "cron(0 0 ? * MON *)"

  actions {
    job_name = aws_glue_job.jobs["model_training"].name
  }

  tags = var.tags
}

resource "aws_glue_trigger" "model_evaluation_trigger" {
  name          = "${local.name_prefix}-model-evaluation-trigger"
  type          = "CONDITIONAL"
  workflow_name = aws_glue_workflow.fraud_detection.name

  predicate {
    conditions {
      job_name = aws_glue_job.jobs["model_training"].name
      state    = "SUCCEEDED"
    }
  }

  actions {
    job_name = aws_glue_job.jobs["model_evaluation"].name
  }

  tags = var.tags
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "job_failure_alarms" {
  for_each = aws_glue_job.jobs

  alarm_name          = "${local.name_prefix}-${each.key}-failure"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name        = "glue.driver.aggregate.numFailedTasks"
  namespace          = "AWS/Glue"
  period             = "300"
  statistic          = "Sum"
  threshold          = "0"
  alarm_description  = "Monitoreo de fallos en trabajo Glue ${each.key}"
  alarm_actions      = var.alarm_actions

  dimensions = {
    JobName = each.value.name
  }

  tags = var.tags
} 