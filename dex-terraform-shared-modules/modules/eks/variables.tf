variable "env" {
  type    = string
}

variable "region" {
  type    = string
}

variable "eks_vpc" {
  type    = string
}

variable "cluster_version" {
  type    = string
}


variable "eks_private_subnets" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "kms_key" {
  description = "Enable KMS key for EKS"
  type        = bool
  default     = false
}
variable "cloudwatch_log_group" {
  description = "Enable CloudWatch log group for EKS"
  type        = bool
  default     = false
}