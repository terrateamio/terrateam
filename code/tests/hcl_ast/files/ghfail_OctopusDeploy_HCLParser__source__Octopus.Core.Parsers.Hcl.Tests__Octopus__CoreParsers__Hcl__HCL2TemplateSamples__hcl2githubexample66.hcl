# Environment
variable "environment" {
  type        = string
  description = "Environment: production, staging or public-playground"
  default     = ""
}

# Environment short name
variable "environment_short" {
  type        = string
  description = "Short version of environment name: prod, stag or play (used in resource names)"
  default     = ""
}

# Global project prefix
variable "project_name_prefix" {
  type        = string
  description = "Global project prefix"
}

# Public network ID
variable "spccloud_public_network_id" {
  type        = string
  description = "Public network ID"
}

# DNS servers added to all instances
variable "public_dns_ips" {
  type        = list(string)
  description = "DNS servers added to all instances"
}

# SSH user added to instances metadata for ansible dynamic inventory
variable "ssh_user" {
  type        = string
  description = "SSH user added to instances metadata for ansible dynamic inventory"
}

# K8S network CIDR
variable "k8s_network_cidr" {
  type        = string
  description = "Kubernetes network CIDR"
  default     = ""
}

# K8S master instance parameters
variable "k8s_master_instance" {
  type        = map(string)
  description = "Kubernetes master instance parameters"
  default     = {}
}

# K8S master instance groups added to metadata for ansible dynamic inventory
# Each item in the list will be added to the corresponding instance number
# i.e. the first item in the list will be added to the first instance and so on
# if there are more instances than items in the list it will restart from the first one
variable "k8s_master_instance_groups" {
  type        = list(string)
  description = "Groups in kubernetes master instances metadata"
  default     = []
}

# K8S master security rules
variable "k8s_master_sec_rules" {
  type        = list
  description = "Kubernetes master security rules"
  default     = []
}

# K8S MetalLB security rules
variable "k8s_metallb_port_sec_rules" {
  type        = list
  description = "Kubernetes MetalLB security rules"
  default     = []
}

# K8S master assigned floating IPs
variable "k8s_master_floatingips" {
  type        = list(string)
  description = "Kubernetes master assigned floating IP addresses"
  default     = []
}

# K8S worker instance parameters
variable "k8s_worker_instance" {
  type        = map(string)
  description = "Kubernetes worker instance parameters"
  default     = {}
}

# K8S worker instance groups added to metadata for ansible dynamic inventory
variable "k8s_worker_instance_groups" {
  type        = list(string)
  description = "Groups in kubernetes worker instances metadata"
  default     = []
}

# K8S worker security rules
variable "k8s_worker_sec_rules" {
  type        = list
  description = "Kubernetes worker security rules"
  default     = []
}

# K8S MetalLB address pairs
variable "k8s_metallb_address_pairs" {
  type        = list
  description = "Kubernetes MetalLB address pairs"
  default     = []
}

# K8S worker assigned floating IPs
variable "k8s_worker_floatingips" {
  type        = list(string)
  description = "Kubernetes worker assigned floating IP addresses"
  default     = []
}

# K8S load balanced ports
variable "k8s_worker_load_balancer_ports" {
  type        = list
  description = "K8S worker load balancer"
  default     = [{ src : 80, dst : 30083 }, { src : 443, dst : 30446 }]
}

# Galera slug name
variable "galera_slug" {
  type        = string
  description = "Galera slug name"
  default     = ""
}

# Galera network CIDR
variable "galera_network_cidr" {
  type        = string
  description = "Galera network CIDR"
  default     = ""
}

# Galera instance parameters
variable "galera_instance" {
  type        = map(string)
  description = "Galera instance parameters"
  default     = {}
}

# Galera load balanced ports
variable "galera_load_balancer_ports" {
  type        = list
  description = "Galera load balanced ports"
  default     = [{ src : 3306, dst : 3306 }]
}

# Galera instance groups added to metadata for ansible dynamic inventory
# Each item in the list will be added to the corresponding instance number
# i.e. the first item in the list will be added to the first instance and so on
# if there are more instances than items in the list it will restart from the first one
variable "galera_instance_groups" {
  type        = list(string)
  description = "Groups in galera instances metadata"
  default     = []
}

# Galera security rules
variable "galera_sec_rules" {
  type        = list
  description = "Galera security rules"
  default     = []
}

# MariaDB slug name
variable "mariadb_slug" {
  type        = string
  description = "MariaDB slug name"
  default     = ""
}

# MariaDB network CIDR
variable "mariadb_network_cidr" {
  type        = string
  description = "MariaDB network CIDR"
  default     = ""
}

# MariaDB instance parameters
variable "mariadb_instance" {
  type        = map(string)
  description = "MariaDB instance parameters"
  default     = {}
}

# MariaDB instance groups added to metadata for ansible dynamic inventory
# Each item in the list will be added to the corresponding instance number
# i.e. the first item in the list will be added to the first instance and so on
# if there are more instances than items in the list it will restart from the first one
variable "mariadb_instance_groups" {
  type        = list(string)
  description = "Groups in mariaDB instances metadata"
  default     = []
}

# MariaDB security rules
variable "mariadb_sec_rules" {
  type        = list
  description = "MariaDB security rules"
  default     = []
}

# Elastic slug name
variable "elastic_slug" {
  type        = string
  description = "Elastic slug name"
  default     = ""
}

# Elastic network CIDR
variable "elastic_network_cidr" {
  type        = string
  description = "Elastic network CIDR"
  default     = ""
}

# Elastic instance parameters
variable "elastic_instance" {
  type        = map(string)
  description = "Elastic instance parameters"
  default     = {}
}

# Elastic load balanced ports
variable "elastic_load_balancer_ports" {
  type        = list
  description = "Elastic load balanced ports"
  default     = [{ src : 9200, dst : 9200 }]
}

# Elastic instance groups added to metadata for ansible dynamic inventory
# Each item in the list will be added to the corresponding instance number
# i.e. the first item in the list will be added to the first instance and so on
# if there are more instances than items in the list it will restart from the first one
variable "elastic_instance_groups" {
  type        = list(string)
  description = "Groups in elastic instances metadata"
  default     = []
}

# Elastic security rules
variable "elastic_sec_rules" {
  type        = list
  description = "Elastic security rules"
  default     = []
}

# Gluster slug name
variable "gluster_slug" {
  type        = string
  description = "Gluster slug name"
  default     = ""
}

# Gluster network CIDR
variable "gluster_network_cidr" {
  type        = string
  description = "Gluster network CIDR"
  default     = ""
}

# Gluster instance parameters
variable "gluster_instance" {
  type        = map(string)
  description = "Gluster instance parameters"
  default     = {}
}

# Gluster instance groups added to metadata for ansible dynamic inventory
# Each item in the list will be added to the corresponding instance number
# i.e. the first item in the list will be added to the first instance and so on
# if there are more instances than items in the list it will restart from the first one
variable "gluster_instance_groups" {
  type        = list(string)
  description = "Groups in gluster instances metadata"
  default     = []
}

# Gluster security rules
variable "gluster_sec_rules" {
  type        = list
  description = "Gluster security rules"
  default     = []
}

locals {
  # Define resource names based on the following convention:
  # {project_name_prefix}-RESOURCE_TYPE
  keypair_pubkey_name = "${var.project_name_prefix}-keypair"
  main_router_name    = "${var.project_name_prefix}-router"
}