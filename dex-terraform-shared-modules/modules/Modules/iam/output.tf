output "arn" {
  value = aws_iam_role.transfer_role.arn
  description = "The ARN of the IAM role"
}