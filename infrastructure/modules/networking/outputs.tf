output "vpc_id" {
  description = "ID de la VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block de la VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs de las subnets públicas"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs de las subnets privadas"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_ids" {
  description = "IDs de los NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

output "internet_gateway_id" {
  description = "ID del Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "public_route_table_id" {
  description = "ID de la tabla de rutas pública"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "IDs de las tablas de rutas privadas"
  value       = aws_route_table.private[*].id
}

output "default_security_group_id" {
  description = "ID del Security Group por defecto"
  value       = aws_security_group.default.id
}

output "vpc_flow_log_group" {
  description = "Nombre del grupo de logs de VPC Flow Logs"
  value       = var.enable_flow_logs ? aws_cloudwatch_log_group.flow_logs[0].name : null
}

output "availability_zones" {
  description = "Lista de zonas de disponibilidad utilizadas"
  value       = data.aws_availability_zones.available.names
}

output "alb_listener_arn" {
  description = "ARN del listener del Application Load Balancer"
  value       = aws_lb_listener.http.arn
}

output "alb_arn" {
  description = "ARN del Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name del Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "target_group_arn" {
  description = "ARN del Target Group por defecto"
  value       = aws_lb_target_group.default.arn
}

output "target_group_name" {
  description = "Nombre del Target Group por defecto"
  value       = aws_lb_target_group.default.name
}

output "test_listener_arn" {
  description = "ARN del listener de prueba del Application Load Balancer"
  value       = aws_lb_listener.test.arn
}

output "alb_security_group_id" {
  description = "ID del Security Group del Application Load Balancer"
  value       = aws_security_group.alb.id
} 