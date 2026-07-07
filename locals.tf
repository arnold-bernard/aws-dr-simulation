#############################################
# Local Variables
# Multi-AZ Disaster Recovery Simulation
#############################################

locals {

  ###########################################
  # Availability Zones
  ###########################################

  azs = slice(
    data.aws_availability_zones.available.names,
    0,
    var.availability_zone_count
  )

  ###########################################
  # Common Naming
  ###########################################

  name_prefix = "${var.project_name}-${var.environment}"

  ###########################################
  # Common Resource Tags
  ###########################################

  common_tags = {

    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"

  }

}