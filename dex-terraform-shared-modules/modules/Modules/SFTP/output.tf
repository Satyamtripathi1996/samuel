output "transfer_server_id" {
  value = aws_transfer_server.transfer.id
}

output "transfer_server_endpoint" {
  value = aws_transfer_server.transfer.endpoint
}

output "sftp_user_name" {
  value = aws_transfer_user.sftp_user.user_name
}

output "iam_role_arn" {
  value = aws_iam_role.transfer_user_role.arn
}

output "cloudwatch_log_group_name" {
  value = aws_cloudwatch_log_group.transfer.name
}
