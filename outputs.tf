#############################################
# Networking Outputs
#############################################

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public Subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private Subnet IDs"
  value       = aws_subnet.private[*].id
}

output "availability_zones" {
  description = "Availability Zones"
  value       = local.azs
}

#############################################
# Load Balancer Outputs
#############################################

output "alb_dns_name" {
  description = "Application Load Balancer DNS Name"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "Application Load Balancer ARN"
  value       = aws_lb.main.arn
}

output "target_group_arn" {
  description = "Target Group ARN"
  value       = aws_lb_target_group.app.arn
}

#############################################
# ECS Outputs
#############################################

output "ecs_cluster_name" {
  description = "ECS Cluster Name"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "ECS Service Name"
  value       = aws_ecs_service.app.name
}

output "task_definition_family" {
  description = "Task Definition Family"
  value       = aws_ecs_task_definition.app.family
}

#############################################
# ECR Outputs
#############################################

output "ecr_repository_name" {
  description = "ECR Repository Name"
  value       = aws_ecr_repository.app.name
}

output "ecr_repository_url" {
  description = "ECR Repository URL"
  value       = aws_ecr_repository.app.repository_url
}

#############################################
# Database Outputs
#############################################

output "database_endpoint" {
  description = "RDS Endpoint"
  value       = aws_db_instance.main.endpoint
}

output "database_port" {
  description = "RDS Port"
  value       = aws_db_instance.main.port
}

output "database_name" {
  description = "Database Name"
  value       = aws_db_instance.main.db_name
}

#############################################
# CloudWatch Outputs
#############################################

output "cloudwatch_log_group" {
  description = "CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.ecs.name
}

output "alb_url" {
  value       = "http://${aws_lb.main.dns_name}"
  description = "ALB URL for accessing the application"
}