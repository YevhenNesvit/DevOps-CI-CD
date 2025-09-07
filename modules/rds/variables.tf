variable "use_aurora" {
  description = "Whether to use Aurora cluster (true) or regular RDS instance (false)"
  type        = bool
  default     = false
}

# ==============================================================================
# Database Configuration
# ==============================================================================

variable "engine" {
  description = "Database engine (postgres for RDS or aurora-postgresql for Aurora)"
  type        = string
  default     = "postgres"
  
  validation {
    condition = contains([
      "postgres", "aurora-postgresql"
    ], var.engine)
    error_message = "Engine must be 'postgres' for RDS or 'aurora-postgresql' for Aurora."
  }
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
  default     = "15.4"
}

variable "instance_class" {
  description = "Database instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB (only for RDS instances, not Aurora)"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum allocated storage for autoscaling (only for RDS instances)"
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "Storage type (only for RDS instances)"
  type        = string
  default     = "gp3"
}

variable "storage_encrypted" {
  description = "Whether the storage should be encrypted"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
  default     = null
}

# ==============================================================================
# Database Credentials
# ==============================================================================

variable "db_name" {
  description = "Name of the database to create"
  type        = string
  default     = "appdb"
}

variable "username" {
  description = "Master username for the database"
  type        = string
  default     = "dbadmin"
}

variable "password" {
  description = "Master password for the database. If not provided, will be auto-generated"
  type        = string
  default     = null
  sensitive   = true
}

variable "manage_master_user_password" {
  description = "Set to true to allow RDS to manage the master user password in Secrets Manager"
  type        = bool
  default     = true
}

# ==============================================================================
# Network Configuration
# ==============================================================================

variable "vpc_id" {
  description = "VPC ID where the database will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to connect to the database"
  type        = list(string)
  default     = []
}

variable "allowed_security_groups" {
  description = "List of security group IDs allowed to connect to the database"
  type        = list(string)
  default     = []
}

# ==============================================================================
# High Availability & Performance
# ==============================================================================

variable "multi_az" {
  description = "Enable Multi-AZ deployment (only for RDS instances)"
  type        = bool
  default     = false
}

variable "publicly_accessible" {
  description = "Whether the database should be publicly accessible"
  type        = bool
  default     = false
}

variable "port" {
  description = "Database port"
  type        = number
  default     = null
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Preferred backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when destroying"
  type        = bool
  default     = false
}

variable "final_snapshot_identifier" {
  description = "Final snapshot identifier"
  type        = string
  default     = null
}

# ==============================================================================
# Aurora Specific Configuration
# ==============================================================================

variable "aurora_instances_count" {
  description = "Number of Aurora instances to create (only for Aurora)"
  type        = number
  default     = 1
}

variable "aurora_serverless_v2_scaling" {
  description = "Aurora Serverless v2 scaling configuration"
  type = object({
    max_capacity = number
    min_capacity = number
  })
  default = null
}

variable "aurora_global_cluster_identifier" {
  description = "Global cluster identifier for Aurora Global Database"
  type        = string
  default     = null
}

# ==============================================================================
# Monitoring & Logging
# ==============================================================================

variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds"
  type        = number
  default     = 60
}

variable "monitoring_role_arn" {
  description = "IAM role ARN for enhanced monitoring"
  type        = string
  default     = null
}

variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch"
  type        = list(string)
  default     = []
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = true
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention period in days"
  type        = number
  default     = 7
}

# ==============================================================================
# Tagging
# ==============================================================================

variable "identifier_prefix" {
  description = "Prefix for database identifier"
  type        = string
  default     = "app"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "myapp"
}

# ==============================================================================
# Parameter Group Configuration
# ==============================================================================

variable "custom_db_parameters" {
  description = "Custom database parameters to override defaults"
  type        = map(string)
  default     = {}
}