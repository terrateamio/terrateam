output "iam_workshop_user_username" {
  value = module.iam_workshop_user.username
}

output "signin_url" {
  value = module.iam_workshop_user.signin_url
}

output "iam_workshop_user_password" {
  value = module.iam_workshop_user.password
}

output "notebook_instance_role_arn" {
  value = (
    module
      .notebook_instance_role
      .notebook_instance_role_arn
  )
}
