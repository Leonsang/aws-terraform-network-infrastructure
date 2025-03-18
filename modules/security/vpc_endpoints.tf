# VPC Endpoints para servicios AWS
# Solo se crean si enable_vpc_endpoints es true

# Security Group para los endpoints
resource "aws_security_group" "vpc_endpoints" {
  count = var.enable_vpc_endpoints ? 1 : 0
  
  name        = "${var.project_name}-${var.environment}-endpoints-sg"
  description = "Security group para VPC endpoints"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-endpoints-sg"
      Environment = var.environment
    },
    var.tags
  )
}

# Endpoint para S3
resource "aws_vpc_endpoint" "s3" {
  count = var.enable_vpc_endpoints ? 1 : 0
  
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  
  route_table_ids = data.aws_route_tables.vpc_route_tables.ids
  
  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-s3-endpoint"
      Environment = var.environment
    },
    var.tags
  )
}

# Endpoint para DynamoDB
resource "aws_vpc_endpoint" "dynamodb" {
  count = var.enable_vpc_endpoints ? 1 : 0
  
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  vpc_endpoint_type = "Gateway"
  
  route_table_ids = data.aws_route_tables.vpc_route_tables.ids
  
  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-dynamodb-endpoint"
      Environment = var.environment
    },
    var.tags
  )
}

# Endpoint para Glue
resource "aws_vpc_endpoint" "glue" {
  count = var.enable_vpc_endpoints ? 1 : 0
  
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.glue"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true
  
  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-glue-endpoint"
      Environment = var.environment
    },
    var.tags
  )
}

# Endpoint para CloudWatch Logs
resource "aws_vpc_endpoint" "logs" {
  count = var.enable_vpc_endpoints ? 1 : 0
  
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true
  
  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-logs-endpoint"
      Environment = var.environment
    },
    var.tags
  )
}

# Endpoint para Kinesis
resource "aws_vpc_endpoint" "kinesis" {
  count = var.enable_vpc_endpoints ? 1 : 0
  
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.kinesis-streams"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true
  
  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-kinesis-endpoint"
      Environment = var.environment
    },
    var.tags
  )
}

# Endpoint para STS (necesario para asumir roles)
resource "aws_vpc_endpoint" "sts" {
  count = var.enable_vpc_endpoints ? 1 : 0
  
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.sts"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true
  
  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-sts-endpoint"
      Environment = var.environment
    },
    var.tags
  )
}

# Data sources
data "aws_region" "current" {}

data "aws_route_tables" "vpc_route_tables" {
  vpc_id = var.vpc_id
}

# Outputs
output "vpc_endpoint_s3_id" {
  description = "ID del endpoint de S3"
  value       = var.enable_vpc_endpoints ? aws_vpc_endpoint.s3[0].id : null
}

output "vpc_endpoint_dynamodb_id" {
  description = "ID del endpoint de DynamoDB"
  value       = var.enable_vpc_endpoints ? aws_vpc_endpoint.dynamodb[0].id : null
}

output "vpc_endpoint_glue_id" {
  description = "ID del endpoint de Glue"
  value       = var.enable_vpc_endpoints ? aws_vpc_endpoint.glue[0].id : null
}

output "vpc_endpoint_logs_id" {
  description = "ID del endpoint de CloudWatch Logs"
  value       = var.enable_vpc_endpoints ? aws_vpc_endpoint.logs[0].id : null
}

output "vpc_endpoint_kinesis_id" {
  description = "ID del endpoint de Kinesis"
  value       = var.enable_vpc_endpoints ? aws_vpc_endpoint.kinesis[0].id : null
}

output "vpc_endpoint_sts_id" {
  description = "ID del endpoint de STS"
  value       = var.enable_vpc_endpoints ? aws_vpc_endpoint.sts[0].id : null
} 