locals {
  model_name = "${var.project_name}-fraud-detection-${var.environment}"
  endpoint_name = "${var.project_name}-fraud-endpoint-${var.environment}"
  training_job_name = "${var.project_name}-training-${var.environment}"
  ecr_repository_name = "${var.project_name}-training-${var.environment}"
}

# Repositorio ECR para la imagen de entrenamiento
resource "aws_ecr_repository" "training" {
  name = local.ecr_repository_name
  tags = var.tags
}

# Rol IAM para SageMaker
resource "aws_iam_role" "sagemaker_role" {
  name = "${var.project_name}-sagemaker-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Política para acceso a S3
resource "aws_iam_role_policy" "sagemaker_s3_policy" {
  name = "${var.project_name}-sagemaker-s3-policy-${var.environment}"
  role = aws_iam_role.sagemaker_role.id

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
          "${var.feature_store_bucket_arn}/*",
          "${var.feature_store_bucket_arn}",
          "${var.model_artifacts_bucket_arn}/*",
          "${var.model_artifacts_bucket_arn}"
        ]
      }
    ]
  })
}

# Política para CloudWatch Logs
resource "aws_iam_role_policy" "sagemaker_cloudwatch_policy" {
  name = "${var.project_name}-sagemaker-cloudwatch-policy-${var.environment}"
  role = aws_iam_role.sagemaker_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

# Grupo de logs para el endpoint
resource "aws_cloudwatch_log_group" "endpoint_logs" {
  name              = "/aws/sagemaker/Endpoints/${local.endpoint_name}"
  retention_in_days = 30
  tags             = var.tags
}

# Training Job
resource "aws_sagemaker_training_job" "fraud_detection" {
  name = local.training_job_name
  role_arn = aws_iam_role.sagemaker_role.arn

  algorithm_specification {
    training_image = "${aws_ecr_repository.training.repository_url}:latest"
    training_input_mode = "File"
  }

  resource_config {
    instance_count = var.training_instance_count
    instance_type = var.training_instance_type
    volume_size_in_gb = 30
  }

  input_data_config {
    channel_name = "training"
    data_source {
      s3_data_source {
        s3_data_type = "S3Prefix"
        s3_uri = "s3://${var.feature_store_bucket_name}/features/"
        s3_data_distribution_type = "FullyReplicated"
      }
    }
  }

  output_data_config {
    s3_output_path = "s3://${var.model_artifacts_bucket_name}/models/"
  }

  hyper_parameters = {
    "n_estimators" = "100"
    "learning_rate" = "0.1"
    "max_depth" = "7"
    "num_leaves" = "31"
  }

  stopping_condition {
    max_runtime_in_seconds = 86400
  }

  tags = var.tags
}

# Configuración del modelo en SageMaker
resource "aws_sagemaker_model" "fraud_detection" {
  name               = local.model_name
  execution_role_arn = aws_iam_role.sagemaker_role.arn

  primary_container {
    image          = "${aws_ecr_repository.training.repository_url}:latest"
    model_data_url = "${var.model_artifacts_bucket_arn}/models/${local.training_job_name}/output/model.tar.gz"
  }

  tags = var.tags

  depends_on = [aws_sagemaker_training_job.fraud_detection]
}

# Configuración del endpoint
resource "aws_sagemaker_endpoint_configuration" "fraud_detection" {
  name = "${local.endpoint_name}-config"

  production_variants {
    variant_name           = "AllTraffic"
    model_name            = aws_sagemaker_model.fraud_detection.name
    initial_instance_count = var.endpoint_instance_count
    instance_type         = var.endpoint_instance_type
  }

  tags = var.tags
}

# Endpoint de SageMaker
resource "aws_sagemaker_endpoint" "fraud_detection" {
  name                 = local.endpoint_name
  endpoint_config_name = aws_sagemaker_endpoint_configuration.fraud_detection.name
  tags                = var.tags
}

# Métricas de CloudWatch para monitoreo
resource "aws_cloudwatch_metric_alarm" "endpoint_invocation_errors" {
  alarm_name          = "${local.endpoint_name}-invocation-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name        = "ModelError"
  namespace          = "AWS/SageMaker"
  period             = "300"
  statistic          = "Sum"
  threshold          = "10"
  alarm_description  = "Monitoreo de errores de invocación del endpoint"
  alarm_actions      = var.alarm_actions

  dimensions = {
    EndpointName = aws_sagemaker_endpoint.fraud_detection.name
    VariantName  = "AllTraffic"
  }

  tags = var.tags
}

# Métricas de latencia
resource "aws_cloudwatch_metric_alarm" "endpoint_latency" {
  alarm_name          = "${local.endpoint_name}-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name        = "ModelLatency"
  namespace          = "AWS/SageMaker"
  period             = "300"
  statistic          = "Average"
  threshold          = "1000"
  alarm_description  = "Monitoreo de latencia alta del endpoint"
  alarm_actions      = var.alarm_actions

  dimensions = {
    EndpointName = aws_sagemaker_endpoint.fraud_detection.name
    VariantName  = "AllTraffic"
  }

  tags = var.tags
}

# Step Function para orquestar el entrenamiento
resource "aws_sfn_state_machine" "training_pipeline" {
  name     = "${var.project_name}-training-pipeline-${var.environment}"
  role_arn = aws_iam_role.step_function_role.arn

  definition = jsonencode({
    StartAt = "StartTraining"
    States = {
      StartTraining = {
        Type = "Task"
        Resource = "arn:aws:states:::sagemaker:createTrainingJob.sync"
        Parameters = {
          TrainingJobName = local.training_job_name
          RoleArn = aws_iam_role.sagemaker_role.arn
          AlgorithmSpecification = {
            TrainingImage = "${aws_ecr_repository.training.repository_url}:latest"
            TrainingInputMode = "File"
          }
          ResourceConfig = {
            InstanceCount = var.training_instance_count
            InstanceType = var.training_instance_type
            VolumeSizeInGB = 30
          }
          InputDataConfig = [
            {
              ChannelName = "training"
              DataSource = {
                S3DataSource = {
                  S3DataType = "S3Prefix"
                  S3Uri = "s3://${var.feature_store_bucket_name}/features/"
                  S3DataDistributionType = "FullyReplicated"
                }
              }
            }
          ]
          OutputDataConfig = {
            S3OutputPath = "s3://${var.model_artifacts_bucket_name}/models/"
          }
          StoppingCondition = {
            MaxRuntimeInSeconds = 86400
          }
        }
        Next = "CreateModel"
      }
      CreateModel = {
        Type = "Task"
        Resource = "arn:aws:states:::sagemaker:createModel"
        Parameters = {
          ModelName = local.model_name
          ExecutionRoleArn = aws_iam_role.sagemaker_role.arn
          PrimaryContainer = {
            Image = "${aws_ecr_repository.training.repository_url}:latest"
            ModelDataUrl = "${var.model_artifacts_bucket_arn}/models/${local.training_job_name}/output/model.tar.gz"
          }
        }
        Next = "CreateEndpointConfig"
      }
      CreateEndpointConfig = {
        Type = "Task"
        Resource = "arn:aws:states:::sagemaker:createEndpointConfig"
        Parameters = {
          EndpointConfigName = "${local.endpoint_name}-config"
          ProductionVariants = [
            {
              VariantName = "AllTraffic"
              ModelName = local.model_name
              InitialInstanceCount = var.endpoint_instance_count
              InstanceType = var.endpoint_instance_type
            }
          ]
        }
        Next = "CreateEndpoint"
      }
      CreateEndpoint = {
        Type = "Task"
        Resource = "arn:aws:states:::sagemaker:createEndpoint"
        Parameters = {
          EndpointName = local.endpoint_name
          EndpointConfigName = "${local.endpoint_name}-config"
        }
        End = true
      }
    }
  })
}

# Rol para Step Functions
resource "aws_iam_role" "step_function_role" {
  name = "${var.project_name}-step-function-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Política para que Step Functions pueda invocar SageMaker
resource "aws_iam_role_policy" "step_function_sagemaker_policy" {
  name = "${var.project_name}-step-function-sagemaker-policy-${var.environment}"
  role = aws_iam_role.step_function_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sagemaker:CreateTrainingJob",
          "sagemaker:DescribeTrainingJob",
          "sagemaker:CreateModel",
          "sagemaker:CreateEndpointConfig",
          "sagemaker:CreateEndpoint",
          "sagemaker:DescribeEndpoint",
          "sagemaker:DescribeEndpointConfig"
        ]
        Resource = "*"
      }
    ]
  })
}

# EventBridge Rule para programar el entrenamiento
resource "aws_cloudwatch_event_rule" "training_schedule" {
  name                = "${var.project_name}-training-schedule-${var.environment}"
  description         = "Programa el entrenamiento periódico del modelo"
  schedule_expression = var.training_schedule

  tags = var.tags
}

# Target para la regla de EventBridge
resource "aws_cloudwatch_event_target" "training_target" {
  rule      = aws_cloudwatch_event_rule.training_schedule.name
  target_id = "StartTrainingPipeline"
  arn       = aws_sfn_state_machine.training_pipeline.arn
  role_arn  = aws_iam_role.eventbridge_role.arn
}

# Rol para EventBridge
resource "aws_iam_role" "eventbridge_role" {
  name = "${var.project_name}-eventbridge-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Política para que EventBridge pueda invocar Step Functions
resource "aws_iam_role_policy" "eventbridge_sfn_policy" {
  name = "${var.project_name}-eventbridge-sfn-policy-${var.environment}"
  role = aws_iam_role.eventbridge_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "states:StartExecution"
        ]
        Resource = aws_sfn_state_machine.training_pipeline.arn
      }
    ]
  })
} 