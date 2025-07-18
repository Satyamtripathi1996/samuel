variable "aws_profile" {
  description = "AWS profile to use for authentication"
  type        = string
  default     = "default"
}

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "env" {
  description = "Environment name"
  type        = string
  default     = "dev"
}
################################################
# S3 Buckets
################################################
variable "buckets_list" {
  type = list(map(string))
}

################################################
# Code Artifacts
################################################
variable "artifact_repo" {
  description = "Name of the CodeArtifact repository"
  type        = string
}

variable "external_packages" {
  description = "Optional list of external connections like public:npmjs"
  type        = map(string)
}
################################################
# VPC Netwok
################################################

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet CIDRs"
  type        = list(string)
}

variable "private_subnets" {
  description = "Private subnets for applications like EKS"
  type        = list(string)
}

variable "database_subnets" {
  description = "RDS subnets for services needing extra segmentation like RDS"
  type        = list(string)
}

variable "elasticache_subnets" {
  description = "Redis subnets for services needing extra segmentation like RDS"
  type        = list(string)
}

################################################
# EKS Cluster
################################################
variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
}

variable "kms_key" {
  description = "Enable KMS key for EKS"
  type        = bool
}

variable "cloudwatch_log_group" {
  description = "Enable CloudWatch log group for EKS"
  type        = bool
}

################################################
# IAM Variables
################################################
variable "iam_groups_names" {
  description = "List of IAM group names to create"
  type        = list(string)
}
variable "iam_developerUser_names" {
  description = "List of IAM Users names to create"
  type        = list(string)
}
variable "iam_devOpsUser_names" {
  description = "List of IAM Users names to create"
  type        = list(string)
}

variable "developer_cgp_arn" {
  description = "Developers custom group policy ARNS"
  type        = list(string)
}

variable "devops_cgp_arn" {
  description = "DevOps custom group policy ARNS"
  type        = list(string)
}

################################################
# RDS Configuration
################################################
variable "rds_config" {
  type = list(map(string))
}

################################################
# RDS Configuration
################################################
variable "amp_config" {
  type = list(map(string))
}

variable "amp_custom_rules" {
  type = list(object({
    source = string
    status = string
    target = string
  }))
}
