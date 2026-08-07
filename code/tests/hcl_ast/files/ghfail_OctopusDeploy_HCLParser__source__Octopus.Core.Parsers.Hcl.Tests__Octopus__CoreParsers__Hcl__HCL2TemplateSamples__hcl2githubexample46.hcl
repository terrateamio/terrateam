#METADATA VARIABLES----------------------
variable "project_name" {
  description = "Used to name resources created throughout AWS"
  type        = string
}

variable "tags" {
  description = "Tags applied to all Airflow related objects"
  type        = map
  default = {
    "Project" = "Airflow"
  }
}


#ADMINISTRATION AND CREDENTIAL VARIABLES------------------
variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Profile from AWS credential file to be used"
  type        = string
  default     = "default"
}

variable "ec2_keypair_name" {
  description = "Name of keypair used to access ec2 instances"
  type        = string
  default     = "Airflow_key"
}

variable "public_key_path" {
  description = "Enter the path to the SSH Public Key to use for ec2 instances."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "private_key_path" {
  description = "Enter the path to the SSH Private Key to use for ec2 instances."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}


#DB VARIABLES-----------------------------------------
variable "db_name" {
  description = "Name of ETL target database"
  type = string
}

variable "db_instance_type" {
  description = "Instance type of ETL target database"
  type = string
  default = "db.t2.large"
}

variable "db_username" {
  description = "Master Username for ETL target database"
  type = string
}

variable "db_password" {
  description = "Master password for ETL target database"
  type = string
}