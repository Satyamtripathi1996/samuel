variable "user_pool_name" {
  type        = string
  description = "Name of the Cognito User Pool"
}

variable "app_client_name" {
  type        = string
  description = "Name of the Cognito User Pool App Client"
}

variable "callback_urls" {
  description = "List of callback URLs"
  type        = list(string)
  default     = ["https://dex-mobile.mocafi"]
}

variable "user_name" {
  type        = string
  description = "Username to create in the user pool"
}

variable "user_email" {
  type        = string
  description = "Email of the user to be created"
}

variable "admin_group_name" {
  type        = string
  description = "Name of the admin group"
}

variable "temporary_password" {
  type        = string
  description = "Name of the admin group"
  default = "Password123!"
}



