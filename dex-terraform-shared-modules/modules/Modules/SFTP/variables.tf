variable "s3_bucket_name" {
  description = "Name of the S3 bucket to use for SFTP home directory"
  type        = string
}

variable "sftp_user_name" {
  description = "SFTP username"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for SFTP user"
  type        = string
}
