terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "dex_sandbox"
}

resource "aws_cognito_user_pool" "user_pool" {
  name                     = var.user_pool_name
  alias_attributes         = ["email"]
  auto_verified_attributes = ["email"]
  mfa_configuration        = "OFF"

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }
}

resource "aws_cognito_user_pool_client" "app_client" {
  name                             = var.app_client_name
  user_pool_id                     = aws_cognito_user_pool.user_pool.id
  generate_secret                  = false
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows              = ["code"]
  allowed_oauth_scopes            = ["email", "openid", "phone"]
  supported_identity_providers    = ["COGNITO"]
  callback_urls                   = var.callback_urls

  read_attributes = [
    "address",
    "birthdate",
    "email"
  ]

  write_attributes = [
    "address",
    "birthdate",
    "email"
  ]
}

resource "aws_cognito_user" "user" {
  user_pool_id = aws_cognito_user_pool.user_pool.id
  username     = var.user_name

  attributes = {
    email          = var.user_email
    email_verified = "true"
  }

  temporary_password         = var.temporary_password
  force_alias_creation       = false
  message_action             = "SUPPRESS"
  desired_delivery_mediums   = ["EMAIL"]

  lifecycle {
    ignore_changes = [temporary_password]
  }
}

resource "aws_cognito_user_group" "admin_group" {
  user_pool_id = aws_cognito_user_pool.user_pool.id
  name         = var.admin_group_name
  description  = "Administrators with full access"
}

