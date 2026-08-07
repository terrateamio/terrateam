variable "region" {
    default = "eu-west-1"
}

variable "ssh_user" {
    default = "ubuntu"
}

variable "ssh_private_key" {
    default = "~/.ssh/my_key.pem"
}

variable "instance_name" {
    default = "my-instance"
}

variable "tags" {
    type = map(string)
    default = {
        name          = "my-instance"
        true          = "Enabled"
        false         = "Disabled"
    }
}

variable "bastion" {
    type = map(string)
    default = {
        host        = "my-jumphost.domain.com"
        user        = "ubuntu"
        private_key = "~/.ssh/id_rsa"
    }
}
