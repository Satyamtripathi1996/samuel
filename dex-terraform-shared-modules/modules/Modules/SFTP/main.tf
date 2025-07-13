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

############################
# CLOUDWATCH LOG GROUP
############################
resource "aws_cloudwatch_log_group" "transfer" {
  name_prefix = "transfer_test_"
}

############################
# IAM ROLE FOR TRANSFER FAMILY (Logging)
############################
data "aws_iam_policy_document" "transfer_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_transfer" {
  name_prefix        = "iam_for_transfer_"
  assume_role_policy = data.aws_iam_policy_document.transfer_assume_role.json
}

############################
# TRANSFER FAMILY SFTP SERVER
############################
resource "aws_transfer_server" "transfer" {
  endpoint_type = "PUBLIC"
  identity_provider_type = "SERVICE_MANAGED"
  logging_role  = aws_iam_role.iam_for_transfer.arn
  protocols     = ["SFTP"]

  structured_log_destinations = [
    "${aws_cloudwatch_log_group.transfer.arn}:*"
  ]

  tags = {
    Name = "sftp-server"
  }
}

############################
# IAM ROLE FOR SFTP USER
############################
resource "aws_iam_role" "transfer_user_role" {
  name_prefix        = "transfer_user_role_"
  assume_role_policy = data.aws_iam_policy_document.transfer_assume_role.json
}

data "aws_iam_policy_document" "transfer_user_policy" {
  statement {
    sid     = "AllowFullAccesstoS3"
    effect  = "Allow"
    actions = ["s3:*"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "transfer_user_policy" {
  name   = "tf-transfer-user-policy"
  role   = aws_iam_role.transfer_user_role.id
  policy = data.aws_iam_policy_document.transfer_user_policy.json
}

############################
# TRANSFER USER
############################
resource "aws_transfer_user" "sftp_user" {
  server_id           = aws_transfer_server.transfer.id
  user_name           = var.sftp_user_name
  role                = aws_iam_role.transfer_user_role.arn
  home_directory_type = "LOGICAL"

  home_directory_mappings {
    entry  = "/"
    target = "/${var.s3_bucket_name}/${var.sftp_user_name}"
  }
}

############################
# S3 USER FOLDER PREFIX
############################
resource "aws_s3_object" "sftp_user_home_prefix" {
  bucket  = var.s3_bucket_name
  key     = "${var.sftp_user_name}/"
  content = ""
}

############################
# SSH KEY FOR SFTP USER
############################
resource "aws_transfer_ssh_key" "sftp_key" {
  server_id = aws_transfer_server.transfer.id
  user_name = aws_transfer_user.sftp_user.user_name
  body      = var.ssh_public_key
}
