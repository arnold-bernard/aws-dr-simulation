#############################################
# AWS Configuration
#############################################

aws_region  = "us-east-1"
aws_profile = "default"

#############################################
# Environment
#############################################

environment = "dev"

project_name = "dr-simulation"

#############################################
# Networking
#############################################

vpc_cidr = "10.0.0.0/16"

availability_zone_count = 3

#############################################
# ECS Configuration
#############################################

ecs_cpu = 256

ecs_memory = 512

container_port = 8080

desired_task_count = 2

#############################################
# Database Configuration
#############################################

db_engine = "postgres"

db_name = "myapp"

db_username = "admin"

db_instance_class = "db.t4g.micro"

db_allocated_storage = 20

#############################################
# Health Checks
#############################################

health_check_path = "/health"

#############################################
# CloudWatch
#############################################

log_retention_days = 7