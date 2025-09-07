output "endpoint" {
  description = "Database endpoint (RDS instance or Aurora cluster writer endpoint)"
  value       = var.use_aurora ? local.aurora_cluster_endpoint : local.rds_endpoint
}

output "reader_endpoint" {
  description = "Aurora cluster reader endpoint (only for Aurora)"
  value       = local.aurora_reader_endpoint
}

output "port" {
  description = "Database port"
  value       = var.use_aurora ? local.aurora_port : local.rds_port
}

output "database_name" {
  description = "Name of the database"
  value       = var.db_name
}

output "username" {
  description = "Database master username"
  value       = var.username
  sensitive   = true
}

# Resource identifiers and ARNs
output "identifier" {
  description = "Database identifier (RDS instance or Aurora cluster identifier)"
  value       = var.use_aurora ? local.aurora_cluster_identifier : local.rds_identifier
}

output "arn" {
  description = "Database ARN (RDS instance or Aurora cluster ARN)"
  value       = var.use_aurora ? local.aurora_cluster_arn : local.rds_arn
}

output "instance_identifiers" {
  description = "List of Aurora cluster instance identifiers (only for Aurora)"
  value       = local.aurora_instance_identifiers
}

output "instance_arns" {
  description = "List of Aurora cluster instance ARNs (only for Aurora)"
  value       = local.aurora_instance_arns
}

# Resource attributes
output "engine" {
  description = "Database engine"
  value       = var.engine
}

output "engine_version" {
  description = "Database engine version"
  value       = var.engine_version
}

output "instance_class" {
  description = "Database instance class"
  value       = var.instance_class
}

output "multi_az" {
  description = "Whether Multi-AZ is enabled (RDS only)"
  value       = var.use_aurora ? null : var.multi_az
}

output "storage_encrypted" {
  description = "Whether storage is encrypted"
  value       = var.storage_encrypted
}

# Network configuration
output "subnet_group_name" {
  description = "DB subnet group name"
  value       = aws_db_subnet_group.main.name
}

output "subnet_group_arn" {
  description = "DB subnet group ARN"
  value       = aws_db_subnet_group.main.arn
}

output "security_group_id" {
  description = "Security group ID for database access"
  value       = aws_security_group.db.id
}

output "security_group_arn" {
  description = "Security group ARN for database access"
  value       = aws_security_group.db.arn
}

# Parameter groups
output "parameter_group_name" {
  description = "DB parameter group name"
  value       = var.use_aurora ? (
    length(aws_db_parameter_group.aurora) > 0 ? aws_db_parameter_group.aurora[0].name : null
  ) : (
    length(aws_db_parameter_group.main) > 0 ? aws_db_parameter_group.main[0].name : null
  )
}

output "cluster_parameter_group_name" {
  description = "Aurora cluster parameter group name (only for Aurora)"
  value       = var.use_aurora ? (
    length(aws_rds_cluster_parameter_group.main) > 0 ? aws_rds_cluster_parameter_group.main[0].name : null
  ) : null
}

# Connection string
output "connection_string" {
  description = "Database connection string (without password)"
  value = var.use_aurora ? (
    local.aurora_cluster_endpoint != null ? 
    "${var.engine}://${var.username}@${local.aurora_cluster_endpoint}:${local.aurora_port}/${var.db_name}" : null
  ) : (
    local.rds_endpoint != null ? 
    "${var.engine}://${var.username}@${local.rds_endpoint}:${local.rds_port}/${var.db_name}" : null
  )
  sensitive = true
}

# Backup configuration
output "backup_retention_period" {
  description = "Backup retention period in days"
  value       = var.backup_retention_period
}

output "backup_window" {
  description = "Backup window"
  value       = var.backup_window
}

output "maintenance_window" {
  description = "Maintenance window"
  value       = var.maintenance_window
}

# Monitoring
output "monitoring_interval" {
  description = "Enhanced monitoring interval"
  value       = var.monitoring_interval
}

output "performance_insights_enabled" {
  description = "Whether Performance Insights is enabled"
  value       = var.performance_insights_enabled
}

# Secrets Manager (for managed passwords)
output "master_user_secret_arn" {
  description = "ARN of the master user secret in Secrets Manager (if manage_master_user_password is true)"
  value = var.manage_master_user_password ? (
    var.use_aurora ? (
      length(aws_rds_cluster.main) > 0 ? aws_rds_cluster.main[0].master_user_secret[0].secret_arn : null
    ) : (
      length(aws_db_instance.main) > 0 ? aws_db_instance.main[0].master_user_secret[0].secret_arn : null
    )
  ) : null
  sensitive = true
}

# General information
output "is_aurora" {
  description = "Whether this is an Aurora cluster"
  value       = var.use_aurora
}

output "tags" {
  description = "Tags applied to resources"
  value       = var.tags
}