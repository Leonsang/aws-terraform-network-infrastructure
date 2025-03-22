module "batch" {
  source = "./batch"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  tags         = var.tags

  # Buckets
  raw_bucket_arn          = var.raw_bucket_arn
  raw_bucket_name         = var.raw_bucket_name
  processed_bucket_name   = var.processed_bucket_name
  processed_bucket_arn    = var.processed_bucket_arn
  feature_store_bucket_name = var.feature_store_bucket_name
  feature_store_bucket_arn  = var.feature_store_bucket_arn
  scripts_bucket          = var.scripts_bucket

  # Networking
  private_subnet_ids     = var.private_subnet_ids

  # Seguridad
  kms_key_arn            = var.kms_key_arn
  security_group_ids     = var.security_group_ids

  # IAM
  glue_role_arn          = var.glue_role_arn
  lambda_role_arn        = var.lambda_role_arn

  # Kinesis
  kinesis_shard_count    = var.kinesis_shard_count
  kinesis_retention_period = var.kinesis_retention_period

  # Lambda
  lambda_runtime         = var.lambda_runtime
  lambda_timeout         = var.lambda_timeout
  lambda_memory_size     = var.lambda_memory_size

  # SNS
  sns_topic_arn         = var.sns_topic_arn
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "processing" {
  name              = "/aws/processing/${var.project_name}-${var.environment}"
  retention_in_days = 30

  tags = var.tags
}

# ECS Execution Role
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.project_name}-${var.environment}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Role
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "ecs_task_role_policy" {
  name = "${var.project_name}-${var.environment}-ecs-task-role-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "${var.raw_bucket_arn}/*",
          "${var.raw_bucket_arn}",
          "${var.processed_bucket_arn}/*",
          "${var.processed_bucket_arn}",
          "${var.feature_store_bucket_arn}/*",
          "${var.feature_store_bucket_arn}",
          "arn:aws:logs:*:*:*"
        ]
      }
    ]
  })
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

# Security Group for ECS Tasks
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-${var.environment}-ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# ECS Task Definition
resource "aws_ecs_task_definition" "app_task" {
  family                   = "${var.project_name}-${var.environment}-app"
  network_mode            = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                     = var.app_cpu
  memory                  = var.app_memory
  execution_role_arn      = aws_iam_role.ecs_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "app"
      image = var.app_image
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}-${var.environment}-app"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = var.tags
}

# Application Load Balancer
# resource "aws_lb" "app" {
#   name               = "${var.project_name}-${var.environment}-alb"
#   internal           = true
#   load_balancer_type = "application"
#   security_groups    = [var.alb_security_group_id]
#   subnets           = var.private_subnet_ids

#   tags = var.tags

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# # ALB Listener
# resource "aws_lb_listener" "app" {
#   load_balancer_arn = aws_lb.app.arn
#   port              = 80
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.app.arn
#   }

#   tags = var.tags
# }

# # Load Balancer Target Group
# resource "aws_lb_target_group" "app" {
#   name        = "${var.project_name}-${var.environment}-app-tg"
#   port        = 80
#   protocol    = "HTTP"
#   vpc_id      = var.vpc_id
#   target_type = "ip"

#   health_check {
#     enabled             = true
#     healthy_threshold   = 2
#     interval            = 30
#     matcher            = "200"
#     path               = "/"
#     port               = "traffic-port"
#     protocol           = "HTTP"
#     timeout            = 5
#     unhealthy_threshold = 2
#   }

#   tags = var.tags

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# ECS Service
resource "aws_ecs_service" "app_service" {
  name            = "${var.project_name}-${var.environment}-app-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  deployment_controller {
    type = "ECS"
  }

  depends_on = [
    aws_ecs_cluster.main,
    aws_ecs_task_definition.app_task,
    aws_security_group.ecs_tasks
  ]
}

# Módulo de Glue
resource "aws_glue_job" "jobs" {
  for_each = var.glue_jobs

  name     = "${var.project_name}-${var.environment}-${each.key}"
  role_arn = var.glue_role_arn

  command {
    script_location = "s3://${var.scripts_bucket}/${each.value.script_path}"
    python_version  = var.glue_python_version
  }

  default_arguments = merge(
    var.default_arguments,
    {
      "--job-language" = "python"
      "--TempDir"      = "s3://${var.scripts_bucket}/temporary"
      "--environment"  = var.environment
    },
    each.value.arguments
  )

  execution_property {
    max_concurrent_runs = each.value.max_concurrent_runs
  }

  glue_version = var.glue_version

  max_retries = each.value.max_retries

  timeout = each.value.timeout_minutes

  worker_type    = var.worker_type
  number_of_workers = var.number_of_workers

  tags = var.tags
}

# CloudWatch Alarms para Glue Jobs
resource "aws_cloudwatch_metric_alarm" "glue_job_failures" {
  for_each = aws_glue_job.jobs

  alarm_name          = "${each.value.name}-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Failure"
  namespace           = "AWS/Glue"
  period             = "300"
  statistic          = "Sum"
  threshold          = "0"
  alarm_description  = "Alarma para fallos en el job de Glue ${each.value.name}"
  alarm_actions      = var.alarm_actions

  dimensions = {
    JobName = each.value.name
  }

  tags = var.tags
} 