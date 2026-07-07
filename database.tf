#############################################
# Generate Database Password
#############################################

resource "random_password" "db" {

  length  = 16
  special = true

}

#############################################
# DB Subnet Group
#############################################

resource "aws_db_subnet_group" "main" {

  name = "${local.name_prefix}-db-subnet-group"

  subnet_ids = aws_subnet.private[*].id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-db-subnet-group"
    }
  )

}

#############################################
# PostgreSQL Database
#############################################

resource "aws_db_instance" "main" {

  identifier = "${local.name_prefix}-postgres"

  engine = var.db_engine

  engine_version = "17"

  instance_class = var.db_instance_class

  allocated_storage = var.db_allocated_storage

  storage_type = "gp3"

  storage_encrypted = true

  db_name = var.db_name

  username = var.db_username

  password = random_password.db.result

  port = 5432

  publicly_accessible = false

  multi_az = true

  db_subnet_group_name = aws_db_subnet_group.main.name

  vpc_security_group_ids = [
    aws_security_group.rds.id
  ]

  backup_retention_period = 7

  backup_window = "02:00-03:00"

  maintenance_window = "Sun:04:00-Sun:05:00"

  deletion_protection = false

  skip_final_snapshot = true

  auto_minor_version_upgrade = true

  apply_immediately = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-postgres"
    }
  )

}


#############################################
# Outputs
#############################################

# Database output declarations are centralized in outputs.tf
