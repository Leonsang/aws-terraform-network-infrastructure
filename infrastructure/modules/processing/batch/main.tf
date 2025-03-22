locals {
  tags = {
    Project     = var.project_name
    Environment = var.environment
    Terraform   = "true"
    Component   = "batch-processing"
  }

  glue_job_name_raw       = "${var.project_name}-${var.environment}-raw-processing"
  glue_job_name_feature   = "${var.project_name}-${var.environment}-feature-engineering"
  step_function_name      = "${var.project_name}-${var.environment}-etl-orchestration"
}

# Data sources para roles existentes
data "aws_iam_role" "glue_role" {
  name = "${var.project_name}-${var.environment}-glue-role"
}

data "aws_iam_role" "step_functions_role" {
  name = "${var.project_name}-${var.environment}-step-functions-role"
}

# Políticas para el rol de Glue
resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = data.aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy" "glue_s3" {
  name = "glue-s3-access"
  role = data.aws_iam_role.glue_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.raw_bucket_arn,
          "${var.raw_bucket_arn}/*",
          var.processed_bucket_arn,
          "${var.processed_bucket_arn}/*",
          var.feature_store_bucket_arn,
          "${var.feature_store_bucket_arn}/*",
          "arn:aws:s3:::${var.scripts_bucket}",
          "arn:aws:s3:::${var.scripts_bucket}/*"
        ]
      }
    ]
  })
}

# Job de Glue para procesamiento inicial
resource "aws_glue_job" "raw_processing" {
  name              = local.glue_job_name_raw
  role_arn          = data.aws_iam_role.glue_role.arn
  glue_version      = "3.0"
  worker_type       = "G.1X"
  number_of_workers = 2

  command {
    script_location = "s3://${var.scripts_bucket}/glue/raw_processing.py"
    python_version  = "3"
  }

  default_arguments = {
    "--enable-metrics"                = "true"
    "--enable-spark-ui"              = "true"
    "--spark-event-logs-path"        = "s3://${var.scripts_bucket}/spark-logs/"
    "--enable-job-insights"          = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--job-language"                 = "python"
    "--input_path"                   = "s3://${var.raw_bucket_name}/data/"
    "--output_path"                  = "s3://${var.processed_bucket_name}/processed/"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  tags = local.tags
}

# Job de Glue para feature engineering
resource "aws_glue_job" "feature_engineering" {
  name              = local.glue_job_name_feature
  role_arn          = data.aws_iam_role.glue_role.arn
  glue_version      = "3.0"
  worker_type       = "G.1X"
  number_of_workers = 3

  command {
    script_location = "s3://${var.scripts_bucket}/glue/feature_engineering.py"
    python_version  = "3"
  }

  default_arguments = {
    "--enable-metrics"                = "true"
    "--enable-spark-ui"              = "true"
    "--spark-event-logs-path"        = "s3://${var.scripts_bucket}/spark-logs/"
    "--enable-job-insights"          = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--job-language"                 = "python"
    "--input_path"                   = "s3://${var.processed_bucket_name}/processed/"
    "--output_path"                  = "s3://${var.feature_store_bucket_name}/features/"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  tags = local.tags
}

# Política para que Step Functions pueda invocar Glue
resource "aws_iam_role_policy" "step_functions_glue" {
  name = "step-functions-glue-access"
  role = data.aws_iam_role.step_functions_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "glue:StartJobRun",
          "glue:GetJobRun",
          "glue:GetJobRuns",
          "glue:BatchStopJobRun"
        ]
        Resource = [
          aws_glue_job.raw_processing.arn,
          aws_glue_job.feature_engineering.arn
        ]
      }
    ]
  })
}

# Política para que Step Functions pueda validar la máquina de estado
resource "aws_iam_role_policy" "step_functions_validate" {
  name = "step-functions-validate-policy"
  role = data.aws_iam_role.step_functions_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "states:ValidateStateMachineDefinition"
        ]
        Resource = "*"
      }
    ]
  })
}

# Política para que Step Functions pueda publicar en SNS
resource "aws_iam_role_policy" "step_functions_sns" {
  name = "step-functions-sns-access"
  role = data.aws_iam_role.step_functions_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = [
          var.sns_topic_arn
        ]
      }
    ]
  })
}

# Política para que Step Functions pueda acceder a los logs
resource "aws_iam_role_policy" "step_functions_logs" {
  name = "step-functions-logs-access"
  role = data.aws_iam_role.step_functions_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      }
    ]
  })
}

# Política para que Step Functions pueda escribir en los logs
resource "aws_iam_role_policy" "step_functions_logs_write" {
  name = "step-functions-logs-write"
  role = data.aws_iam_role.step_functions_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "${aws_cloudwatch_log_group.step_functions.arn}:*"
        ]
      }
    ]
  })
}

# Step Function para orquestación
resource "aws_sfn_state_machine" "etl_orchestration" {
  name     = local.step_function_name
  role_arn = data.aws_iam_role.step_functions_role.arn

  definition = jsonencode({
    StartAt = "ProcessRawData"
    States = {
      ProcessRawData = {
        Type = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Parameters = {
          JobName = aws_glue_job.raw_processing.name
          Arguments = {
            "--input_path" = "s3://${var.raw_bucket_name}/data/"
            "--output_path" = "s3://${var.processed_bucket_name}/processed/"
          }
        }
        Next = "FeatureEngineering"
        Retry = [
          {
            ErrorEquals = ["States.TaskFailed"]
            IntervalSeconds = 60
            MaxAttempts = 3
            BackoffRate = 2.0
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next = "NotifyFailure"
          }
        ]
      }
      FeatureEngineering = {
        Type = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Parameters = {
          JobName = aws_glue_job.feature_engineering.name
          Arguments = {
            "--input_path" = "s3://${var.processed_bucket_name}/processed/"
            "--output_path" = "s3://${var.feature_store_bucket_name}/features/"
          }
        }
        Next = "NotifySuccess"
        Retry = [
          {
            ErrorEquals = ["States.TaskFailed"]
            IntervalSeconds = 60
            MaxAttempts = 3
            BackoffRate = 2.0
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next = "NotifyFailure"
          }
        ]
      }
      NotifySuccess = {
        Type = "Task"
        Resource = "arn:aws:states:::sns:publish"
        Parameters = {
          TopicArn = var.sns_topic_arn
          Message = "ETL pipeline completed successfully"
        }
        End = true
      }
      NotifyFailure = {
        Type = "Task"
        Resource = "arn:aws:states:::sns:publish"
        Parameters = {
          TopicArn = var.sns_topic_arn
          Message = "ETL pipeline failed"
        }
        End = true
      }
    }
  })

  logging_configuration {
    level = "ALL"
    include_execution_data = true
    log_destination = "${aws_cloudwatch_log_group.step_functions.arn}:*"
  }

  tags = local.tags
}

# CloudWatch Log Group para Step Functions
resource "aws_cloudwatch_log_group" "step_functions" {
  name              = "/aws/step-functions/${local.step_function_name}"
  retention_in_days = 30
  tags = local.tags
}

# CloudWatch Event Rule para programar la ejecución
resource "aws_cloudwatch_event_rule" "etl_schedule" {
  name                = "${var.project_name}-${var.environment}-etl-schedule"
  description         = "Programa la ejecución del pipeline ETL"
  schedule_expression = var.schedule_expression

  tags = local.tags
}

resource "aws_cloudwatch_event_target" "etl_target" {
  rule      = aws_cloudwatch_event_rule.etl_schedule.name
  target_id = "ETLOrchestration"
  arn       = aws_sfn_state_machine.etl_orchestration.arn
  role_arn  = data.aws_iam_role.step_functions_role.arn
}

# Outputs
output "glue_jobs" {
  description = "Información de los jobs de Glue"
  value = {
    raw_processing = {
      name = aws_glue_job.raw_processing.name
      arn  = aws_glue_job.raw_processing.arn
    }
    feature_engineering = {
      name = aws_glue_job.feature_engineering.name
      arn  = aws_glue_job.feature_engineering.arn
    }
  }
}

output "step_function" {
  description = "Información de la Step Function"
  value = {
    name = aws_sfn_state_machine.etl_orchestration.name
    arn  = aws_sfn_state_machine.etl_orchestration.arn
  }
}

# Glue Job
resource "aws_glue_job" "processing" {
  name     = "${var.project_name}-${var.environment}-processing"
  role_arn = var.glue_role_arn

  command {
    script_location = "s3://${var.scripts_bucket}/glue/processing.py"
  }

  default_arguments = {
    "--job-language"               = "python"
    "--continuous-log-logGroup"    = "/aws-glue/jobs/${var.project_name}-${var.environment}-processing"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-metrics"            = "true"
  }

  execution_property {
    max_concurrent_runs = 1
  }
}

# Glue Database
resource "aws_glue_catalog_database" "main" {
  name = "${var.project_name}_${var.environment}_db"
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.tags
}

# ECS Service
resource "aws_ecs_service" "main" {
  name            = "${var.project_name}-${var.environment}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = var.security_group_ids
    subnets         = var.private_subnet_ids
  }

  tags = var.tags
}

# ECS Task Definition
resource "aws_ecs_task_definition" "main" {
  family                   = "${var.project_name}-${var.environment}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = 256
  memory                  = 512
  execution_role_arn      = var.lambda_role_arn
  task_role_arn          = var.lambda_role_arn

  container_definitions = jsonencode([
    {
      name  = "${var.project_name}-${var.environment}-container"
      image = "amazon/aws-lambda-python:3.9"
      cpu   = 256
      memory = 512
      essential = true
      environment = [
        {
          name  = "ENVIRONMENT"
          value = var.environment
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}-${var.environment}"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = var.tags
}

# Kinesis Stream
resource "aws_kinesis_stream" "main" {
  name             = "${var.project_name}-${var.environment}-stream"
  shard_count      = var.kinesis_shard_count
  retention_period = var.kinesis_retention_period

  encryption_type = "KMS"
  kms_key_id     = var.kms_key_arn

  tags = var.tags
}

# DynamoDB Table
resource "aws_dynamodb_table" "main" {
  name           = "${var.project_name}-${var.environment}-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  stream_enabled = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "id"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  tags = var.tags
}

# Glue Crawler
resource "aws_glue_crawler" "main" {
  database_name = aws_glue_catalog_database.main.name
  name          = "${var.project_name}-${var.environment}-crawler"
  role          = var.glue_role_arn

  s3_target {
    path = "s3://${var.raw_bucket_name}/raw-data"
  }

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  configuration = jsonencode({
    Version = 1.0
    CrawlerOutput = {
      Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
    }
  })

  tags = var.tags
} 