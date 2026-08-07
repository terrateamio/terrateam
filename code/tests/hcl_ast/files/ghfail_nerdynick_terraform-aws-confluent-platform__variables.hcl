variable "extra_template_vars" {
    type = map
    default = {}
    description = "A collection of variables to use in all template rendering."
}
variable "vpc_id" {
    type = string
}
variable "subnet_ids" {
    type = list(string)
}
variable "multi_az" {
    type = bool
    default = true
    description = "Should all the instances be proportianently spread among all the Subnets or just stay in the first subnet"
}
variable "image_id" {
    type = string
}
variable "enable_sg_creation" {
    type = bool
    default = true
}
variable "security_group_ids" {
    type = list(string)
    default = []
}
variable "key_pair" {
    type = string
}
variable "default_tags" {
    type = map
    default = {}
}
variable "dns_zone_id" {
    type = string
}
variable "enable_dns_creation" {
    type = bool
    default = true
    description = "Generate Route53 entries for all created resources"
}

#Monitoring
variable "monitoring_security_group_ids"{
    type = list
    default = []
    description = "Collection of Security Groups that need access to monitoring this component"
}
variable "monitoring_cidrs"{
    type = list
    default = []
    description = "Collection of CIDRS that need access to monitoring this component"
}
variable "prometheus_enabled" {
    type = bool
    default = true
}
variable "jolokia_enabled" {
    type = bool
    default = true
}

#User Data
variable "user_data_template_vars" {
    type = map
    default = {}
    description = "A collection of variables to give to the user data template during render. These will be in addition to the vars already passed in the extra_template_vars param as well as node_count, node_name, node_dns, node_devices."
}


###########################
# Zookeeper Vars
###########################
variable "zookeeper_servers" {
    type = number
    default = 1
}

#Instance Related Vars
variable "zookeeper_image_id" {
    type = string
    default = ""
}
variable "zookeeper_instance_type" {
    type = string
    default = "t3.small"
}
variable "zookeeper_root_volume_size" {
    type = number
    default = 15
}
variable "zookeeper_key_pair" {
    type = string
    default = ""
}
variable "zookeeper_tags" {
    type = map
    default = {}
}

#Network Related Vars
variable "zookeeper_subnet_ids" {
    type = list(string)
    default = []
}
variable "zookeeper_multi_az" {
    type = bool
    default = true
    description = "Should all the instances be proportianently spread among all the Subnets or just stay in the first subnet"
}

variable "zookeeper_security_group_ids" {
    type = list
    default = []
}

#DNS Related Vars
variable "zookeeper_dns_zone_id" {
    type = string
    default = ""
}
variable "zookeeper_dns_ttl" {
    type = string
    default = "300"
}

variable "zookeeper_name_template" {
    type = string
    default = "zk$${format('%02f', itemcount)}"
}
variable "zookeeper_dns_template" {
    type = string
    default = "$${name}"
}
variable "zookeeper_sg_name" {
    type = string
    default = "CP_Zookeeper"
}
variable "zookeeper_enable_sg_creation" {
    type = bool
    default = true
}
variable "zookeeper_enable_dns_creation" {
    type = bool
    default = true
    description = "Generate Route53 entries for all created resources"
}
variable "zookeeper_port_external_range" {
    type = list(object({from=number,to=number}))
    default = [{from=2181,to=2181}]
    description = "External Port Ranges to Expose"
}
variable "zookeeper_port_internal_range" {
    type = list(object({from=number,to=number}))
    default = [{from=2181,to=2181},{from=2888,to=2888},{from=3888,to=3888}]
    description = "Internal Port Ranges to Expose"
}
variable "zookeeper_external_access_security_group_ids" {
    type = list
    default = []
    description = "Other Security Groups you will tro grant access to the externalized ports"
}
variable "zookeeper_external_access_cidrs" {
    type = list
    default = []
    description = "CIDRs you will tro grant access to the externalized ports"
}
variable "kafka_broker_sg_id" {
    type = string
    default = ""
}


#EBS Volumes
variable "zookeeper_extra_ebs_volumes" {
    type = list(object({
        name: string,
        device_name: string,
        encrypted: bool,
        kms_key_id: string,
        size: number,
        type: string,
        tags: map(string)
    }))
    default = []
}

variable "zookeeper_vol_trans_log_size" {
    type = number
    default = 500
}
variable "zookeeper_vol_trans_log_device_name" {
    type = string
    default = "/dev/sdf"
}
variable "zookeeper_vol_storage_size" {
    type = number
    default = 500
}
variable "zookeeper_vol_storage_device_name" {
    type = string
    default = "/dev/sdg"
}

#Monitoring
variable "zookeeper_prometheus_port" {
    type = number
    default = 8079
    description = "Port on which the Prometheus Agent is running"
}
variable "zookeeper_jolokia_port" {
    type = number
    default = 7770
    description = "Port on which the Jolokia Agent is running"
}

#User Data
variable "zookeeper_extra_template_vars" {
    type = map
    default = {}
}
variable "zookeeper_user_data_template" {
    type = string
    default = ""
    description = "A Shell script to run upon instance startup"
}

variable "zookeeper_user_data_template_vars" {
    type = map
    default = {}
    description = "A collection of variables to give to the user data template during render. These will be in addition to the vars already passed in the zookeeper_extra_template_vars param as well as node_count, node_name, node_dns, node_devices."
}

###########################
# Broker Vars
###########################
variable "kafka_broker_servers" {
    type = number
    default = 1
}

#Instance Related Vars
variable "kafka_broker_image_id" {
    type = string
    default = ""
}
variable "kafka_broker_instance_type" {
    type = string
    default = "t3.medium"
}
variable "kafka_broker_root_volume_size" {
    type = number
    default = 30
}
variable "kafka_broker_key_pair" {
    type = string
    default = ""
}
variable "kafka_broker_tags" {
    type = map
    default = {}
}

#Network Related Vars
variable "kafka_broker_subnet_ids" {
    type = list(string)
    default = []
}
variable "kafka_broker_multi_az" {
    type = bool
    default = true
    description = "Should all the instances be proportianently spread among all the Subnets or just stay in the first subnet"
}

variable "kafka_broker_security_group_ids" {
    type = list
    default = []
}

#DNS Related Vars
variable "kafka_broker_dns_zone_id" {
    type = string
    default = ""
}
variable "kafka_broker_dns_ttl" {
    type = string
    default = "300"
}

variable "kafka_broker_name_template" {
    type = string
    default = "kfk$${format('%02f', itemcount)}"
}
variable "kafka_broker_dns_template" {
    type = string
    default = "$${name}"
}
variable "kafka_broker_sg_name" {
    type = string
    default = "CP_Kafka_Broker"
}
variable "kafka_broker_port_external_range" {
    type = list(object({from=number,to=number}))
    default = [{from=9091,to=9093},{from:8090,to:8091}]
    description = "External Port Ranges to Expose"
}
variable "kafka_broker_port_internal_range" {
    type = list(object({from=number,to=number}))
    default = [{from=9091,to=9092},{from:8090,to:8091}]
    description = "Internal Port Ranges to Expose"
}
variable "kafka_broker_external_access_security_group_ids" {
    type = list
    default = []
    description = "Other Security Groups you will tro grant access to the externalized ports"
}
variable "kafka_broker_external_access_cidrs" {
    type = list
    default = []
    description = "CIDRs you will tro grant access to the externalized ports"
}
variable "kafka_broker_enable_sg_creation" {
    type = bool
    default = true
}
variable "kafka_broker_enable_dns_creation" {
    type = bool
    default = true
    description = "Generate Route53 entries for all created resources"
}


#EBS Volumes
variable "kafka_broker_extra_ebs_volumes" {
    type = list(object({
        name: string,
        device_name: string,
        encrypted: bool,
        kms_key_id: string,
        size: number,
        type: string,
        tags: map(string)
    }))
    default = []
}

variable "kafka_broker_vol_data_size" {
    type = number
    default = 500
}
variable "kafka_broker_vol_data_device_name" {
    type = string
    default = "/dev/sdf"
}
variable "kafka_broker_vol_data_type" {
    type = string
    default = null
}

#Monitoring
variable "kafka_broker_prometheus_port" {
    type = number
    default = 8080
    description = "Port on which the Prometheus Agent is running"
}
variable "kafka_broker_jolokia_port" {
    type = number
    default = 7771
    description = "Port on which the Jolokia Agent is running"
}

#User Data
variable "kafka_broker_extra_template_vars" {
    type = map
    default = {}
}
variable "kafka_broker_user_data_template" {
    type = string
    default = ""
    description = "A Shell script to run upon instance startup"
}

variable "kafka_broker_user_data_template_vars" {
    type = map
    default = {}
    description = "A collection of variables to give to the user data template during render. These will be in addition to the vars already passed in the kafka_broker_extra_template_vars param as well as node_count, node_name, node_dns, node_devices."
}

###########################
# Connect Vars
###########################
variable "kafka_connect_servers" {
    type = number
    default = 0
}

#Instance Related Vars
variable "kafka_connect_image_id" {
    type = string
    default = ""
}
variable "kafka_connect_instance_type" {
    type = string
    default = "t3.medium"
}
variable "kafka_connect_root_volume_size" {
    type = number
    default = 15
}
variable "kafka_connect_key_pair" {
    type = string
    default = ""
}
variable "kafka_connect_tags" {
    type = map
    default = {}
}

#Network Related Vars
variable "kafka_connect_subnet_ids" {
    type = list(string)
    default = []
}
variable "kafka_connect_multi_az" {
    type = bool
    default = true
    description = "Should all the instances be proportianently spread among all the Subnets or just stay in the first subnet"
}

variable "kafka_connect_security_group_ids" {
    type = list
    default = []
}

#DNS Related Vars
variable "kafka_connect_dns_zone_id" {
    type = string
    default = ""
}
variable "kafka_connect_dns_ttl" {
    type = string
    default = "300"
}

variable "kafka_connect_name_template" {
    type = string
    default = "connect$${format('%02f', itemcount)}"
}
variable "kafka_connect_dns_template" {
    type = string
    default = "$${name}"
}
variable "kafka_connect_sg_name" {
    type = string
    default = "CP_Kafka_Connect"
}
variable "kafka_connect_enable_sg_creation" {
    type = bool
    default = true
}
variable "kafka_connect_enable_dns_creation" {
    type = bool
    default = true
    description = "Generate Route53 entries for all created resources"
}
variable "kafka_connect_port_external_range" {
    type = list(object({from=number,to=number}))
    default = [{from=8083,to=8083}]
    description = "External Port Ranges to Expose"
}
variable "kafka_connect_port_internal_range" {
    type = list(object({from=number,to=number}))
    default = [{from=8083,to=8083}]
    description = "Internal Port Ranges to Expose"
}
variable "kafka_connect_external_access_security_group_ids" {
    type = list
    default = []
    description = "Other Security Groups you will tro grant access to the externalized ports"
}
variable "kafka_connect_external_access_cidrs" {
    type = list
    default = []
    description = "CIDRs you will tro grant access to the externalized ports"
}

#EBS Volumes
variable "kafka_connect_extra_ebs_volumes" {
    type = list(object({
        name: string,
        device_name: string,
        encrypted: bool,
        kms_key_id: string,
        size: number,
        type: string,
        tags: map(string)
    }))
    default = []
}

#Monitoring
variable "kafka_connect_prometheus_port" {
    type = number
    default = 8077
    description = "Port on which the Prometheus Agent is running"
}
variable "kafka_connect_jolokia_port" {
    type = number
    default = 7773
    description = "Port on which the Jolokia Agent is running"
}

#User Data
variable "kafka_connect_extra_template_vars" {
    type = map
    default = {}
}
variable "kafka_connect_user_data_template" {
    type = string
    default = ""
    description = "A Shell script to run upon instance startup"
}

variable "kafka_connect_user_data_template_vars" {
    type = map
    default = {}
    description = "A collection of variables to give to the user data template during render. These will be in addition to the vars already passed in the kafka_connect_extra_template_vars param as well as node_count, node_name, node_dns, node_devices."
}

###########################
# Control Center Vars
###########################
variable "control_center_servers" {
    type = number
    default = 0
}

#Instance Related Vars
variable "control_center_image_id" {
    type = string
    default = ""
}
variable "control_center_instance_type" {
    type = string
    default = "t3.medium"
}
variable "control_center_root_volume_size" {
    type = number
    default = 15
}
variable "control_center_key_pair" {
    type = string
    default = ""
}
variable "control_center_tags" {
    type = map
    default = {}
}

#Network Related Vars
variable "control_center_subnet_ids" {
    type = list(string)
    default = []
}
variable "control_center_multi_az" {
    type = bool
    default = true
    description = "Should all the instances be proportianently spread among all the Subnets or just stay in the first subnet"
}

variable "control_center_security_group_ids" {
    type = list
    default = []
}

#DNS Related Vars
variable "control_center_dns_zone_id" {
    type = string
    default = ""
}
variable "control_center_dns_ttl" {
    type = string
    default = "300"
}

variable "control_center_name_template" {
    type = string
    default = "ccc$${format('%02f', itemcount)}"
}
variable "control_center_dns_template" {
    type = string
    default = "$${name}"
}
variable "control_center_sg_name" {
    type = string
    default = "CP_Control_Center"
}
variable "control_center_enable_sg_creation" {
    type = bool
    default = true
}
variable "control_center_enable_dns_creation" {
    type = bool
    default = true
    description = "Generate Route53 entries for all created resources"
}
variable "control_center_port_external_range" {
    type = list(object({from=number,to=number}))
    default = [{from=9021,to=9021}]
    description = "External Port Ranges to Expose"
}
variable "control_center_port_internal_range" {
    type = list(object({from=number,to=number}))
    default = [{from=9021,to=9021}]
    description = "Internal Port Ranges to Expose"
}
variable "control_center_external_access_security_group_ids" {
    type = list
    default = []
    description = "Other Security Groups you will tro grant access to the externalized ports"
}
variable "control_center_external_access_cidrs" {
    type = list
    default = []
    description = "CIDRs you will tro grant access to the externalized ports"
}


#EBS Volumes
variable "control_center_extra_ebs_volumes" {
    type = list(object({
        name: string,
        device_name: string,
        encrypted: bool,
        kms_key_id: string,
        size: number,
        type: string,
        tags: map(string)
    }))
    default = []
}

variable "control_center_vol_data_size" {
    type = number
    default = 300
}
variable "control_center_vol_data_device_name" {
    type = string
    default = "/dev/sdf"
}

#User Data
variable "control_center_extra_template_vars" {
    type = map
    default = {}
}
variable "control_center_user_data_template" {
    type = string
    default = ""
    description = "A Shell script to run upon instance startup"
}

variable "control_center_user_data_template_vars" {
    type = map
    default = {}
    description = "A collection of variables to give to the user data template during render. These will be in addition to the vars already passed in the control_center_extra_template_vars param as well as node_count, node_name, node_dns, node_devices."
}

###########################
# KSQL Vars
###########################
variable "ksql_servers" {
    type = number
    default = 0
}

#Instance Related Vars
variable "ksql_image_id" {
    type = string
    default = ""
}
variable "ksql_instance_type" {
    type = string
    default = "t3.medium"
}
variable "ksql_root_volume_size" {
    type = number
    default = 15
}
variable "ksql_key_pair" {
    type = string
    default = ""
}
variable "ksql_tags" {
    type = map
    default = {}
}

#Network Related Vars
variable "ksql_subnet_ids" {
    type = list(string)
    default = []
}
variable "ksql_multi_az" {
    type = bool
    default = true
    description = "Should all the instances be proportianently spread among all the Subnets or just stay in the first subnet"
}

variable "ksql_security_group_ids" {
    type = list
    default = []
}

#DNS Related Vars
variable "ksql_dns_zone_id" {
    type = string
    default = ""
}
variable "ksql_dns_ttl" {
    type = string
    default = "300"
}

variable "ksql_name_template" {
    type = string
    default = "ksql$${format('%02f', itemcount)}"
}
variable "ksql_dns_template" {
    type = string
    default = "$${name}"
}
variable "ksql_sg_name" {
    type = string
    default = "CP_KSQL"
}
variable "ksql_enable_sg_creation" {
    type = bool
    default = true
}
variable "ksql_enable_dns_creation" {
    type = bool
    default = true
    description = "Generate Route53 entries for all created resources"
}
variable "ksql_port_external_range" {
    type = list(object({from=number,to=number}))
    default = [{from=8088,to=8088}]
    description = "External Port Ranges to Expose"
}
variable "ksql_port_internal_range" {
    type = list(object({from=number,to=number}))
    default = [{from=8088,to=8088}]
    description = "Internal Port Ranges to Expose"
}
variable "ksql_external_access_security_group_ids" {
    type = list
    default = []
    description = "Other Security Groups you will tro grant access to the externalized ports"
}
variable "ksql_external_access_cidrs" {
    type = list
    default = []
    description = "CIDRs you will tro grant access to the externalized ports"
}


#EBS Volumes
variable "ksql_extra_ebs_volumes" {
    type = list(object({
        name: string,
        device_name: string,
        encrypted: bool,
        kms_key_id: string,
        size: number,
        type: string,
        tags: map(string)
    }))
    default = []
}

variable "ksql_vol_data_size" {
    type = number
    default = 100
}
variable "ksql_vol_data_device_name" {
    type = string
    default = "/dev/sdf"
}

#Monitoring
variable "ksql_prometheus_port" {
    type = number
    default = 8076
    description = "Port on which the Prometheus Agent is running"
}
variable "ksql_jolokia_port" {
    type = number
    default = 7774
    description = "Port on which the Jolokia Agent is running"
}

#User Data
variable "ksql_extra_template_vars" {
    type = map
    default = {}
}
variable "ksql_user_data_template" {
    type = string
    default = ""
    description = "A Shell script to run upon instance startup"
}

variable "ksql_user_data_template_vars" {
    type = map
    default = {}
    description = "A collection of variables to give to the user data template during render. These will be in addition to the vars already passed in the ksql_extra_template_vars param as well as node_count, node_name, node_dns, node_devices."
}

###########################
# RESTProxy Vars
###########################
variable "rest_proxy_servers" {
    type = number
    default = 0
}

#Instance Related Vars
variable "rest_proxy_image_id" {
    type = string
    default = ""
}
variable "rest_proxy_instance_type" {
    type = string
    default = "t3.medium"
}
variable "rest_proxy_root_volume_size" {
    type = number
    default = 15
}
variable "rest_proxy_key_pair" {
    type = string
    default = ""
}
variable "rest_proxy_tags" {
    type = map
    default = {}
}

#Network Related Vars
variable "rest_proxy_subnet_ids" {
    type = list(string)
    default = []
}
variable "rest_proxy_multi_az" {
    type = bool
    default = true
    description = "Should all the instances be proportianently spread among all the Subnets or just stay in the first subnet"
}

variable "rest_proxy_security_group_ids" {
    type = list
    default = []
}

#DNS Related Vars
variable "rest_proxy_dns_zone_id" {
    type = string
    default = ""
}
variable "rest_proxy_dns_ttl" {
    type = string
    default = "300"
}

variable "rest_proxy_name_template" {
    type = string
    default = "rest$${format('%02f', itemcount)}"
}
variable "rest_proxy_dns_template" {
    type = string
    default = "$${name}"
}
variable "rest_proxy_sg_name" {
    type = string
    default = "CP_REST_Proxy"
}
variable "rest_proxy_enable_sg_creation" {
    type = bool
    default = true
}
variable "rest_proxy_enable_dns_creation" {
    type = bool
    default = true
    description = "Generate Route53 entries for all created resources"
}
variable "rest_proxy_port_external_range" {
    type = list(object({from=number,to=number}))
    default = [{from=8082,to=8082}]
    description = "External Port Ranges to Expose"
}
variable "rest_proxy_port_internal_range" {
    type = list(object({from=number,to=number}))
    default = [{from=8082,to=8082}]
    description = "Internal Port Ranges to Expose"
}
variable "rest_proxy_external_access_security_group_ids" {
    type = list
    default = []
    description = "Other Security Groups you will tro grant access to the externalized ports"
}
variable "rest_proxy_external_access_cidrs" {
    type = list
    default = []
    description = "CIDRs you will tro grant access to the externalized ports"
}

#Monitoring
variable "rest_proxy_prometheus_port" {
    type = number
    default = 8075
    description = "Port on which the Prometheus Agent is running"
}
variable "rest_proxy_jolokia_port" {
    type = number
    default = 7775
    description = "Port on which the Jolokia Agent is running"
}

#User Data
variable "rest_proxy_extra_template_vars" {
    type = map
    default = {}
}
variable "rest_proxy_user_data_template" {
    type = string
    default = ""
    description = "A Shell script to run upon instance startup"
}

variable "rest_proxy_user_data_template_vars" {
    type = map
    default = {}
    description = "A collection of variables to give to the user data template during render. These will be in addition to the vars already passed in the rest_proxy_extra_template_vars param as well as node_count, node_name, node_dns, node_devices."
}

###########################
# Schema Registry Vars
###########################
variable "schema_registry_servers" {
    type = number
    default = 0
}

#Instance Related Vars
variable "schema_registry_image_id" {
    type = string
    default = ""
}
variable "schema_registry_instance_type" {
    type = string
    default = "t3.medium"
}
variable "schema_registry_root_volume_size" {
    type = number
    default = 15
}
variable "schema_registry_key_pair" {
    type = string
    default = ""
}
variable "schema_registry_tags" {
    type = map
    default = {}
}

#Network Related Vars
variable "schema_registry_subnet_ids" {
    type = list(string)
    default = []
}
variable "schema_registry_multi_az" {
    type = bool
    default = true
    description = "Should all the instances be proportianently spread among all the Subnets or just stay in the first subnet"
}

variable "schema_registry_security_group_ids" {
    type = list
    default = []
}

#DNS Related Vars
variable "schema_registry_dns_zone_id" {
    type = string
    default = ""
}
variable "schema_registry_dns_ttl" {
    type = string
    default = "300"
}

variable "schema_registry_name_template" {
    type = string
    default = "sr$${format('%02f', itemcount)}"
}
variable "schema_registry_dns_template" {
    type = string
    default = "$${name}"
}
variable "schema_registry_sg_name" {
    type = string
    default = "CP_Schema_Registry"
}
variable "schema_registry_enable_sg_creation" {
    type = bool
    default = true
}
variable "schema_registry_enable_dns_creation" {
    type = bool
    default = true
    description = "Generate Route53 entries for all created resources"
}
variable "schema_registry_port_external_range" {
    type = list(object({from=number,to=number}))
    default = [{from=8081,to=8081}]
    description = "External Port Ranges to Expose"
}
variable "schema_registry_port_internal_range" {
    type = list(object({from=number,to=number}))
    default = [{from=8081,to=8081}]
    description = "Internal Port Ranges to Expose"
}
variable "schema_registry_external_access_security_group_ids" {
    type = list
    default = []
    description = "Other Security Groups you will tro grant access to the externalized ports"
}
variable "schema_registry_external_access_cidrs" {
    type = list
    default = []
    description = "CIDRs you will tro grant access to the externalized ports"
}

#Monitoring
variable "schema_registry_prometheus_port" {
    type = number
    default = 8078
    description = "Port on which the Prometheus Agent is running"
}
variable "schema_registry_jolokia_port" {
    type = number
    default = 7772
    description = "Port on which the Jolokia Agent is running"
}

#User Data
variable "schema_registry_extra_template_vars" {
    type = map
    default = {}
}
variable "schema_registry_user_data_template" {
    type = string
    default = ""
    description = "A Shell script to run upon instance startup"
}

variable "schema_registry_user_data_template_vars" {
    type = map
    default = {}
    description = "A collection of variables to give to the user data template during render. These will be in addition to the vars already passed in the schema_registry_extra_template_vars param as well as node_count, node_name, node_dns, node_devices."
}
