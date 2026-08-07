variable "region" {
    default     = "eu-west-1"
}

variable "instance_name" {
    default = "test-instance"
}

variable "ssh_user" {
    default     = "ubuntu"
}

variable "ssh_key" {
    type = map(string)
    default = {
        dev    = "~/.ssh/dev.pem"
        prod   = "~/.ssh/prod.pem"
    }
}

variable "ssh_key_name" {
    type = map(string)
    default = {
        dev   = "dev"
        prod  = "prod"
    }
}

variable "security_group" {
  type        = string
  default     = "remote-access-sg"
}

variable "tags" {
    type = map(string)
    default = {
        name          = "test-instance"
        true          = "Enabled"
        false         = "Disabled"
    }
}
