variable "external_ecr_service_account" {
  description = "The name of the service account in the EKS cluster that will use this role to pull images from external ECR repositories."
  type        = list(string)
  default     = []
}

variable "eks_module_url" {
  description = "The URL of the EKS module to use."
}