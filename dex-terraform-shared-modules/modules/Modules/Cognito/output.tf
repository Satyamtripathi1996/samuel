output "user_pool_id" {
  value = aws_cognito_user_pool.user_pool.id
}

output "user_pool_name" {
  value = aws_cognito_user_pool.user_pool.name
}

output "admin_group_name" {
  value = aws_cognito_user_group.admin_group.name
  
}

output "app_client_name" {
  value = aws_cognito_user_pool_client.app_client.name
  
}




