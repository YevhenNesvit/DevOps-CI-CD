variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "django-eks-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.27"
}

variable "subnet_ids" {
  description = "List of subnet IDs for EKS cluster"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for node groups"
  type        = list(string)
}

variable "node_instance_types" {
  description = "Instance types for EKS node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 4
}

variable "node_min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}