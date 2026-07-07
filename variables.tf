#############################################
# Project Variables
# Multi-AZ Disaster Recovery Simulation
#############################################

#############################################
# AWS Configuration
#############################################

variable "aws_region" {
  description = "AWS Region where resources will be created."
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use."
  type        = string
  default     = "default"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"
}

#############################################
# Project Information
#############################################

variable "project_name" {
  description = "Project name used for resource naming."
  type        = string
  default     = "dr-simulation"
}

#############################################
# Networking
#############################################

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zone_count" {
  description = "Number of Availability Zones to use."
  type        = number
  default     = 3
}

#############################################
# ECS Configuration
#############################################

variable "ecs_cpu" {
  description = "CPU units for ECS Task."
  type        = number
  default     = 256
}

variable "ecs_memory" {
  description = "Memory (MB) for ECS Task."
  type        = number
  default     = 512
}

variable "container_port" {
  description = "Port exposed by the application container."
  type        = number
  default     = 8080
}

variable "desired_task_count" {
  description = "Desired number of ECS Tasks."
  type        = number
  default     = 2
}

#############################################
# Database Configuration
#############################################

variable "db_engine" {
  description = "Database engine."
  type        = string
  default     = "postgres"
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "myapp"
}

variable "db_username" {
  description = "Master username."
  type        = string
  default     = "admin"
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB."
  type        = number
  default     = 20
}

#############################################
# Load Balancer
#############################################

variable "health_check_path" {
  description = "Application health check endpoint."
  type        = string
  default     = "/health"
}

#############################################
# CloudWatch
#############################################

variable "log_retention_days" {
  description = "CloudWatch log retention."
  type        = number
  default     = 7
}