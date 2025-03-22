locals {
  asg_name = "${var.project_name}-asg-${var.environment}"
}

# Launch Template
resource "aws_launch_template" "main" {
  name_prefix   = "${var.project_name}-lt-${var.environment}"
  image_id      = var.ami_id
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = false
    security_groups            = var.security_group_ids
  }

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    environment = var.environment
    region      = var.aws_region
  }))

  iam_instance_profile {
    name = aws_iam_instance_profile.main.name
  }

  monitoring {
    enabled = true
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.root_volume_size
      volume_type          = "gp3"
      delete_on_termination = true
      encrypted            = true
    }
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "main" {
  name                = local.asg_name
  desired_capacity    = var.desired_capacity
  max_size           = var.max_size
  min_size           = var.min_size
  target_group_arns  = var.target_group_arns
  vpc_zone_identifier = var.subnet_ids
  health_check_type  = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  dynamic "tag" {
    for_each = merge(
      var.tags,
      {
        Name = local.asg_name
      }
    )
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Políticas de escalado basadas en CPU
resource "aws_autoscaling_policy" "cpu_scale_up" {
  name                   = "${local.asg_name}-cpu-scale-up"
  autoscaling_group_name = aws_autoscaling_group.main.name
  adjustment_type        = "ChangeInCapacity"
  policy_type           = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.cpu_target_value
  }
}

# Políticas de escalado basadas en memoria
resource "aws_autoscaling_policy" "memory_scale_up" {
  name                   = "${local.asg_name}-memory-scale-up"
  autoscaling_group_name = aws_autoscaling_group.main.name
  adjustment_type        = "ChangeInCapacity"
  policy_type           = "TargetTrackingScaling"

  target_tracking_configuration {
    customized_metric_specification {
      metric_dimension {
        name  = "AutoScalingGroupName"
        value = aws_autoscaling_group.main.name
      }
      metric_name = "MemoryUtilization"
      namespace   = "AWS/EC2"
      statistic   = "Average"
    }
    target_value = var.memory_target_value
  }
}

# Rol IAM para las instancias
resource "aws_iam_role" "instance" {
  name = "${var.project_name}-instance-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Perfil de instancia
resource "aws_iam_instance_profile" "main" {
  name = "${var.project_name}-instance-profile-${var.environment}"
  role = aws_iam_role.instance.name
}

# Política para el rol de instancia
resource "aws_iam_role_policy" "instance" {
  name = "${var.project_name}-instance-policy-${var.environment}"
  role = aws_iam_role.instance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "ec2:DescribeTags",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "logs:CreateLogStream",
          "logs:CreateLogGroup"
        ]
        Resource = "*"
      }
    ]
  })
}

# CloudWatch Alarm para CPU alto
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${local.asg_name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = var.cpu_high_threshold
  alarm_description   = "Monitoreo de CPU alto en el ASG"
  alarm_actions       = var.alarm_actions

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }

  tags = var.tags
}

# CloudWatch Alarm para memoria alta
resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "${local.asg_name}-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = var.memory_high_threshold
  alarm_description   = "Monitoreo de memoria alta en el ASG"
  alarm_actions       = var.alarm_actions

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }

  tags = var.tags
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "scaling" {
  dashboard_name = "${var.project_name}-scaling-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.main.name],
            [".", "MemoryUtilization", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "CPU y Memoria del ASG"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", aws_autoscaling_group.main.name],
            [".", "GroupPendingInstances", ".", "."],
            [".", "GroupTerminatingInstances", ".", "."]
          ]
          view    = "timeSeries"
          stacked = true
          region  = var.aws_region
          title   = "Estado de Instancias del ASG"
          period  = 300
        }
      }
    ]
  })
} 