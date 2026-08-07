module "iam_workshop_user" {
  source = "./iam_workshop_user"
  
  username = var.workshop_user_username
}

module "notebook_instance" {
  source = "./notebook_instance"
  
  notebook_instance_role_arn = (
    module.notebook_instance_role
          .notebook_instance_role_arn
  )
  
  notebook_instance_name = var.notebook_instance_name
}

module "notebook_instance_role" {
  source = "./notebook_instance_role"
  
  notebook_instance_role_name = (
    var.notebook_instance_role_name
  )
}