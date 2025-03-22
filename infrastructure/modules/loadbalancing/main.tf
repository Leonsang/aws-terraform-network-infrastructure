locals {
  alb_name = "${var.project_name}-alb-${var.environment}"
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = local.alb_name
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets           = var.subnet_ids

  enable_deletion_protection = var.enable_deletion_protection
  enable_http2              = true
  idle_timeout             = var.idle_timeout

  access_logs {
    bucket  = var.access_logs_bucket
    prefix  = "alb-logs"
    enabled = true
  }

  tags = merge(
    var.tags,
    {
      Name = local.alb_name
    }
  )
}

# Listener HTTPS
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Acceso no autorizado"
      status_code  = "403"
    }
  }
}

# Listener HTTP (redirección a HTTPS)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Target Group principal
resource "aws_lb_target_group" "main" {
  name                 = "${var.project_name}-tg-${var.environment}"
  port                = var.target_port
  protocol            = "HTTP"
  vpc_id              = var.vpc_id
  target_type         = "instance"
  deregistration_delay = 30

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 15
    matcher            = "200-299"
    path               = var.health_check_path
    port               = "traffic-port"
    protocol           = "HTTP"
    timeout            = 5
    unhealthy_threshold = 3
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = var.enable_stickiness
  }

  tags = var.tags
}

# Regla para el listener HTTPS
resource "aws_lb_listener_rule" "main" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "high_latency" {
  alarm_name          = "${local.alb_name}-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = var.latency_threshold
  alarm_description   = "Alta latencia en el ALB"
  alarm_actions       = var.alarm_actions

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "high_5xx" {
  alarm_name          = "${local.alb_name}-high-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.error_threshold
  alarm_description   = "Alto número de errores 5XX"
  alarm_actions       = var.alarm_actions

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  tags = var.tags
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "loadbalancer" {
  dashboard_name = "${var.project_name}-loadbalancer-${var.environment}"

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
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.main.arn_suffix],
            [".", "TargetResponseTime", ".", "."],
            [".", "HTTPCode_Target_2XX_Count", ".", "."],
            [".", "HTTPCode_Target_4XX_Count", ".", "."],
            [".", "HTTPCode_Target_5XX_Count", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Métricas del ALB"
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
            ["AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", aws_lb_target_group.main.arn_suffix],
            [".", "UnHealthyHostCount", ".", "."]
          ]
          view    = "timeSeries"
          stacked = true
          region  = var.aws_region
          title   = "Estado de los Hosts"
          period  = 300
        }
      }
    ]
  })
} 