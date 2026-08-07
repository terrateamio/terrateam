variable "instance_name"{
  description = "Name of instance"
  type = string
}

variable "region_name"{
  description = "Name of region"
  type = string
  default = "us-east-1"
}

variable "ami"{
  description = "Name of ami"
  type = string
  default = "ami-0cc96feef8c6bbff3"
}


variable "placement_group"{
  description = "Name of placement group"
  type = string
  default = ""
}

variable "instance_type"{
  description = "type of instance"
  type = string
  default = "t2.micro"
}

variable "vpc_id"{
  description = "vpc_id"
  type = string
  default = ""
}

variable "instance_count"{
  description = "number of instances"
  type = number
}