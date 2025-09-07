resource "aws_db_instance" "main" {
  count = var.use_aurora ? 0 : 1

  # Basic configuration
  identifier     = "${var.identifier_prefix}-${var.environment}-db"
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  # Database configuration
  db_name  = var.db_name
  username = var.username
  password = var.password != null ? var.password : (
    var.manage_master_user_password ? null : random_password.master_password[0].result
  )
  manage_master_user_password = var.manage_master_user_password
  port                       = local.db_port

  # Storage configuration
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type         = var.storage_type
  storage_encrypted    = var.storage_encrypted
  kms_key_id          = var.kms_key_id

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = var.publicly_accessible

  # High availability
  multi_az = var.multi_az

  # Parameter group
  parameter_group_name = aws_db_parameter_group.main[0].name

  # Backup configuration
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window     = var.maintenance_window
  
  # Snapshot configuration
  deletion_protection       = var.deletion_protection
  skip_final_snapshot      = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : local.final_snapshot_identifier

  # Monitoring and logging
  monitoring_interval                   = var.monitoring_interval
  monitoring_role_arn                  = var.monitoring_role_arn
  enabled_cloudwatch_logs_exports      = local.enabled_cloudwatch_logs_exports
  performance_insights_enabled         = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_retention_period

  # Auto minor version upgrade
  auto_minor_version_upgrade = false

  # Copy tags to snapshots
  copy_tags_to_snapshot = true

  tags = merge(
    var.tags,
    {
      Name        = "${var.identifier_prefix}-${var.environment}-db"
      Environment = var.environment
      Project     = var.project
      Engine      = var.engine
      EngineMode  = "provisioned"
    }
  )

  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      password,
      final_snapshot_identifier,
    ]
  }

  depends_on = [
    aws_db_subnet_group.main,
    aws_security_group.db,
    aws_db_parameter_group.main
  ]
}

# ==============================================================================
# RDS Instance Outputs
# ==============================================================================

locals {
  rds_endpoint = var.use_aurora ? null : (
    length(aws_db_instance.main) > 0 ? aws_db_instance.main[0].endpoint : null
  )
  rds_port = var.use_aurora ? null : (
    length(aws_db_instance.main) > 0 ? aws_db_instance.main[0].port : null
  )
  rds_identifier = var.use_aurora ? null : (
    length(aws_db_instance.main) > 0 ? aws_db_instance.main[0].identifier : null
  )
  rds_arn = var.use_aurora ? null : (
    length(aws_db_instance.main) > 0 ? aws_db_instance.main[0].arn : null
  )
}