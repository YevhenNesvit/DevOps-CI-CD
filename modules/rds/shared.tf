resource "random_password" "master_password" {
  count   = var.password == null && !var.manage_master_user_password ? 1 : 0
  length  = 16
  special = true
}

# ==============================================================================
# DB Subnet Group
# ==============================================================================

resource "aws_db_subnet_group" "main" {
  name       = "${var.identifier_prefix}-${var.environment}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(
    var.tags,
    {
      Name        = "${var.identifier_prefix}-${var.environment}-subnet-group"
      Environment = var.environment
      Project     = var.project
    }
  )
}

# ==============================================================================
# Security Group
# ==============================================================================

resource "aws_security_group" "db" {
  name_prefix = "${var.identifier_prefix}-${var.environment}-db-"
  vpc_id      = var.vpc_id
  description = "Security group for ${var.use_aurora ? "Aurora" : "RDS"} database"

  tags = merge(
    var.tags,
    {
      Name        = "${var.identifier_prefix}-${var.environment}-db-sg"
      Environment = var.environment
      Project     = var.project
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Security group rules
resource "aws_security_group_rule" "db_ingress_cidr" {
  count             = length(var.allowed_cidr_blocks) > 0 ? 1 : 0
  type              = "ingress"
  from_port         = local.db_port
  to_port           = local.db_port
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = aws_security_group.db.id
  description       = "Database access from CIDR blocks"
}

resource "aws_security_group_rule" "db_ingress_sg" {
  count                    = length(var.allowed_security_groups)
  type                     = "ingress"
  from_port                = local.db_port
  to_port                  = local.db_port
  protocol                 = "tcp"
  source_security_group_id = var.allowed_security_groups[count.index]
  security_group_id        = aws_security_group.db.id
  description              = "Database access from security group ${var.allowed_security_groups[count.index]}"
}

resource "aws_security_group_rule" "db_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.db.id
  description       = "All outbound traffic"
}

# ==============================================================================
# Parameter Groups
# ==============================================================================

# RDS Parameter Group
resource "aws_db_parameter_group" "main" {
  count  = var.use_aurora ? 0 : 1
  family = local.parameter_group_family
  name   = "${var.identifier_prefix}-${var.environment}-params"

  description = "Parameter group for ${var.engine} RDS instance"

  dynamic "parameter" {
    for_each = local.db_parameters
    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.identifier_prefix}-${var.environment}-params"
      Environment = var.environment
      Project     = var.project
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Aurora Cluster Parameter Group
resource "aws_rds_cluster_parameter_group" "main" {
  count  = var.use_aurora ? 1 : 0
  family = local.parameter_group_family
  name   = "${var.identifier_prefix}-${var.environment}-cluster-params"

  description = "Cluster parameter group for ${var.engine} Aurora cluster"

  dynamic "parameter" {
    for_each = local.db_parameters
    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.identifier_prefix}-${var.environment}-cluster-params"
      Environment = var.environment
      Project     = var.project
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Aurora DB Parameter Group (for instances in cluster)
resource "aws_db_parameter_group" "aurora" {
  count  = var.use_aurora ? 1 : 0
  family = local.parameter_group_family
  name   = "${var.identifier_prefix}-${var.environment}-aurora-params"

  description = "DB parameter group for ${var.engine} Aurora instances"

  dynamic "parameter" {
    for_each = local.aurora_db_parameters
    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.identifier_prefix}-${var.environment}-aurora-params"
      Environment = var.environment
      Project     = var.project
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ==============================================================================
# Local Values
# ==============================================================================

locals {
  # Database port mapping
  default_ports = {
    postgres            = 5432
    "aurora-postgresql" = 5432
  }

  db_port = var.port != null ? var.port : local.default_ports[var.engine]

  # Parameter group family mapping
  parameter_group_families = {
    "postgres"            = "postgres15"
    "aurora-postgresql"  = "aurora-postgresql15"
  }

  parameter_group_family = local.parameter_group_families[var.engine]

  # Default PostgreSQL parameters
  default_postgres_params = {
    max_connections                = "100"
    log_statement                 = "all"
    work_mem                      = "4MB"
    shared_preload_libraries      = "pg_stat_statements"
    log_min_duration_statement    = "1000"
    log_checkpoints              = "on"
    log_lock_waits               = "on"
  }

  # Engine-specific parameters (тільки PostgreSQL)
  db_parameters = merge(
    local.default_postgres_params,
    var.custom_db_parameters
  )

  # Aurora-specific parameters (for DB parameter group)
  aurora_db_parameters = var.use_aurora ? {
    shared_preload_libraries = contains(keys(local.db_parameters), "shared_preload_libraries") ? 
      local.db_parameters["shared_preload_libraries"] : "pg_stat_statements"
  } : {}

  # CloudWatch logs exports (тільки PostgreSQL)
  enabled_cloudwatch_logs_exports = length(var.enabled_cloudwatch_logs_exports) > 0 ? 
    var.enabled_cloudwatch_logs_exports : ["postgresql"]

  # Final snapshot identifier
  final_snapshot_identifier = var.final_snapshot_identifier != null ? 
    var.final_snapshot_identifier : 
    "${var.identifier_prefix}-${var.environment}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
}