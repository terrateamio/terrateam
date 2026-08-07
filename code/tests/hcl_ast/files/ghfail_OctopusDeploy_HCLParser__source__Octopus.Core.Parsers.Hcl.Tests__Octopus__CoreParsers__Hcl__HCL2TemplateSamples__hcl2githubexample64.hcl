variable "name" {
  type        = string
  description = "Name of the Auto Scaling Groups"
}

variable "blue_max_size" {
  type        = number
  description = "The maximum size of the blue autoscaling group"
}

variable "blue_min_size" {
  type        = number
  description = "The minimum size of the blue autoscaling group"
}

variable "blue_desired_capacity" {
  type        = number
  description = "The number of Amazon EC2 instances that should be running in the blue autoscaling roup"
}

variable "blue_instance_type" {
  type        = string
  description = "The Blue instance type to launch"
}

variable "blue_ami" {
  type        = string
  description = "The EC2 image ID to launch in the Blue autoscaling group"
}

variable "blue_user_data" {
  type        = string
  description = "The user data to provide when launching the Blue instances"
  default     = "# Hello World"
}

variable "blue_disk_volume_size" {
  type        = number
  description = "The size of the EBS volume in GB for the Blue instances"
  default     = 8
}

variable "blue_disk_volume_type" {
  type        = string
  description = "The EBS volume type for the Blue instances"
  default     = "gp2"
}

variable "green_max_size" {
  type        = number
  description = "The maximum size of the green autoscaling group"
}

variable "green_min_size" {
  type        = number
  description = "The minimum size of the green autoscaling group"
}

variable "green_desired_capacity" {
  type        = number
  description = "The number of Amazon EC2 instances that should be running in the green autoscaling roup"
}

variable "green_instance_type" {
  type        = string
  description = "The Green instance type to launch"
}

variable "green_ami" {
  type        = string
  description = "The EC2 image ID to launch in the Green autoscaling group"
}

variable "green_user_data" {
  type        = string
  description = "The user data to provide when launching the Green instances"
  default     = "# Hello World"
}

variable "green_disk_volume_size" {
  type        = number
  description = "The size of the EBS volume in GB for the Green instances"
  default     = 8
}

variable "green_disk_volume_type" {
  type        = string
  description = "The EBS volume type for the Green instances"
  default     = "gp2"
}

variable "key_name" {
  type        = string
  description = "The key name that should be used for the instance"
  default     = null
}

variable "loadbalancers" {
  type        = list(string)
  description = "A list of load balancer names to add to the autoscaling groups"
  default     = []
}

variable "security_groups" {
  type        = list(string)
  description = "A list of associated security group IDS"
  default     = []
}

variable "iam_instance_profile" {
  type        = string
  description = "The IAM instance profile to associate with launched instances"
  default     = null
}

variable "associate_public_ip_address" {
  type        = bool
  description = "Associate a public ip address with an instance in a VPC"
  default     = false
}

variable "subnets" {
  type        = list(string)
  description = "A list of subnet IDs to launch resources in"
  default     = []
}

variable "health_check_grace_period" {
  type        = number
  description = "Time (in seconds) after instance comes into service before checking health"
  default     = 300
}

variable "termination_policies" {
  type        = list(string)
  description = "Order in termination policies to apply when choosing instances to terminate."
  default     = ["Default"]
}

variable "target_group_arns" {
  type        = list(string)
  description = "A list of aws_alb_target_group ARNs, for use with Application Load Balancing"
  default     = []
}

variable "health_check_type" {
  type        = string
  description = "The health check type to apply to the Autoscaling groups."
  default     = "ELB"
}

variable "tags" {
  type        = list(map(string))
  description = "List as a map of additional tags"
  default     = []
}

variable "spot_price" {
  type        = string
  description = "Spot price you want to pay for your instances. If not set this module will use on-demand instances"
  default     = null
}

variable "wait_for_capacity_timeout" {
  type        = string
  description = "A maximum duration that Terraform should wait for ASG instances to be healthy before timing out. Setting this to 0 causes Terraform to skip all Capacity Waiting behavior."
  default     = "10m"
}

variable "initial_lifecycle_hooks" {
  type        = list(map(string))
  description = "One or more [Lifecycle Hooks](http://docs.aws.amazon.com/autoscaling/latest/userguide/lifecycle-hooks.html) to attach to the autoscaling group before instances are launched. The syntax is exactly the same as the separate [`aws_autoscaling_lifecycle_hook`](https://www.terraform.io/docs/providers/aws/r/autoscaling_lifecycle_hooks.html) resource, without the autoscaling_group_name attribute"
  default     = []
}