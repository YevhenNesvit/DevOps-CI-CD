resource "aws_rds_cluster" "main" {
  count = var.use_aurora ? 1 : 0

  # Basic configuration
  cluster_identifier = "${var.identifier_prefix}-${var.environment}-aurora"
  engine             = var.engine
  engine_version     = var.engine_version

  # Database configuration
  database_name   = var.db_name
  master_username = var.username
  master_password = var.password != null ? var.password : (
    var.manage_master_user_password ? null : random_password.master_password[0].result
  )
  manage_master_user_password = var.manage_master_user_password
  port                       = local.db_port

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]

  # Parameter groups
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main[0].name

  # Backup configuration
  backup_retention_period = var.backup_retention_period
  preferred_backup_window = var.backup_window
  preferred_maintenance_window = var.maintenance_window

  # Snapshot configuration
  deletion_protection       = var.deletion_protection
  skip_final_snapshot      = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.final_snapshot_identifier}-cluster"

  # Storage encryption
  storage_encrypted = var.storage_encrypted
  kms_key_id       = var.kms_key_id

  # Monitoring and logging
  enabled_cloudwatch_logs_exports = local.enabled_cloudwatch_logs_exports

  # Global cluster configuration
  global_cluster_identifier = var.aurora_global_cluster_identifier

  # Aurora Serverless v2 configuration
  dynamic "serverlessv2_scaling_configuration" {
    for_each = var.aurora_serverless_v2_scaling != null ? [var.aurora_serverless_v2_scaling] : []
    content {
      max_capacity = serverlessv2_scaling_configuration.value.max_capacity
      min_capacity = serverlessv2_scaling_configuration.value.min_capacity
    }
  }

  # Copy tags to snapshots
  copy_tags_to_snapshot = true

  tags = merge(
    var.tags,
    {
      Name        = "${var.identifier_prefix}-${var.environment}-aurora"
      Environment = var.environment
      Project     = var.project
      Engine      = var.engine
      EngineMode  = "aurora"
    }
  )

  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      master_password,
      final_snapshot_identifier,
      global_cluster_identifier,
    ]
  }

  depends_on = [
    aws_db_subnet_group.main,
    aws_security_group.db,
    aws_rds_cluster_parameter_group.main
  ]
}

# ==============================================================================
# Aurora Cluster Instances
# ==============================================================================

resource "aws_rds_cluster_instance" "cluster_instances" {
  count = var.use_aurora ? var.aurora_instances_count : 0

  # Basic configuration
  identifier         = "${var.identifier_prefix}-${var.environment}-aurora-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.main[0].id
  instance_class     = var.instance_class
  engine             = aws_rds_cluster.main[0].engine
  engine_version     = aws_rds_cluster.main[0].engine_version

  # Parameter group
  db_parameter_group_name = length(aws_db_parameter_group.aurora) > 0 ? aws_db_parameter_group.aurora[0].name : null

  # Monitoring
  monitoring_interval                   = var.monitoring_interval
  monitoring_role_arn                  = var.monitoring_role_arn
  performance_insights_enabled         = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_retention_period

  # Auto minor version upgrade
  auto_minor_version_upgrade = false

  # Public accessibility
  publicly_accessible = var.publicly_accessible

  # Copy tags to snapshots
  copy_tags_to_snapshot = true

  tags = merge(
    var.tags,
    {
      Name        = "${var.identifier_prefix}-${var.environment}-aurora-${count.index + 1}"
      Environment = var.environment
      Project     = var.project
      Engine      = var.engine
      EngineMode  = "aurora"
      InstanceType = count.index == 0 ? "writer" : "reader"
    }
  )

  lifecycle {
    prevent_destroy = false
  }

  depends_on = [
    aws_rds_cluster.main,
    aws_db_parameter_group.aurora
  ]
}

# ==============================================================================
# Aurora Cluster Outputs
# ==============================================================================

locals {
  aurora_cluster_endpoint = var.use_aurora ? (
    length(aws_rds_cluster.main) > 0 ? aws_rds_cluster.main[0].endpoint : null
  ) : null
  
  aurora_reader_endpoint = var.use_aurora ? (
    length(aws_rds_cluster.main) > 0 ? aws_rds_cluster.main[0].reader_endpoint : null
  ) : null
  
  aurora_port = var.use_aurora ? (
    length(aws_rds_cluster.main) > 0 ? aws_rds_cluster.main[0].port : null
  ) : null
  
  aurora_cluster_identifier = var.use_aurora ? (
    length(aws_rds_cluster.main) > 0 ? aws_rds_cluster.main[0].cluster_identifier : null
  ) : null
  
  aurora_cluster_arn = var.use_aurora ? (
    length(aws_rds_cluster.main) > 0 ? aws_rds_cluster.main[0].arn : null
  ) : null

  aurora_instance_identifiers = var.use_aurora ? [
    for instance in aws_rds_cluster_instance.cluster_instances : instance.identifier
  ] : []

  aurora_instance_arns = var.use_aurora ? [
    for instance in aws_rds_cluster_instance.cluster_instances : instance.arn
  ] : []
}