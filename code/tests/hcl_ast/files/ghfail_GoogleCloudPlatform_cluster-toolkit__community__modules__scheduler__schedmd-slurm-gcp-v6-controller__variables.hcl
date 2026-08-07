/**
 * Copyright (C) SchedMD LLC.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

###########
# GENERAL #
###########

variable "project_id" {
  type        = string
  description = "Project ID to create resources in."
}

variable "deployment_name" {
  description = "Name of the deployment."
  type        = string
}

variable "slurm_cluster_name" {
  type        = string
  description = <<-EOD
    Cluster name, used for resource naming and slurm accounting.
    If not provided it will default to the first 8 characters of the deployment name (removing any invalid characters).
  EOD
  default     = null

  validation {
    condition     = var.slurm_cluster_name == null || can(regex("^[a-z]([-a-z0-9]{0,19})$", var.slurm_cluster_name))
    error_message = "Variable 'slurm_cluster_name' must be a match of regex '^[a-z]([-a-z0-9]{0,19})$'."
  }
}

variable "region" {
  type        = string
  description = "The default region to place resources in."
}

variable "zone" {
  type        = string
  description = <<EOD
Zone where the instances should be created. If not specified, instances will be
spread across available zones in the region.
EOD
  default     = null
}

##########
# BUCKET #
##########

variable "create_bucket" {
  description = <<-EOD
    Create GCS bucket instead of using an existing one.
  EOD
  type        = bool
  default     = true
}

variable "bucket_name" {
  description = <<-EOD
    Name of GCS bucket.
    Ignored when 'create_bucket' is true.
  EOD
  type        = string
  default     = null
}

variable "bucket_dir" {
  description = "Bucket directory for cluster files to be put into. If not specified, then one will be chosen based on slurm_cluster_name."
  type        = string
  default     = null
}

#####################
# CONTROLLER: CLOUD # See variables_controller_instance.tf for the controller instance variables.
#####################

#########
# LOGIN #
#########

variable "login_nodes" {
  description = "List of slurm login instance definitions."
  type = list(object({
    group_name = string
    access_config = optional(list(object({
      nat_ip       = string
      network_tier = string
    })))
    additional_disks = optional(list(object({
      disk_name                           = optional(string)
      device_name                         = optional(string)
      disk_size_gb                        = optional(number)
      disk_type                           = optional(string)
      disk_labels                         = optional(map(string), {})
      auto_delete                         = optional(bool, true)
      boot                                = optional(bool, false)
      disk_resource_manager_tags          = optional(map(string), {})
      disk_encryption_key                 = optional(string)
      disk_encryption_key_service_account = optional(string)
    })), [])
    additional_networks = optional(list(object({
      access_config = optional(list(object({
        nat_ip       = string
        network_tier = string
      })), [])
      alias_ip_range = optional(list(object({
        ip_cidr_range         = string
        subnetwork_range_name = string
      })), [])
      ipv6_access_config = optional(list(object({
        network_tier = string
      })), [])
      network            = optional(string)
      network_ip         = optional(string, "")
      nic_type           = optional(string)
      queue_count        = optional(number)
      stack_type         = optional(string)
      subnetwork         = optional(string)
      subnetwork_project = optional(string)
    })), [])
    bandwidth_tier             = optional(string, "platform_default")
    can_ip_forward             = optional(bool, false)
    disk_auto_delete           = optional(bool, true)
    disk_labels                = optional(map(string), {})
    disk_resource_manager_tags = optional(map(string), {})
    disk_size_gb               = optional(number)
    disk_type                  = optional(string, "n1-standard-1")
    enable_confidential_vm     = optional(bool, false)
    enable_oslogin             = optional(bool, true)
    enable_shielded_vm         = optional(bool, false)
    gpu = optional(object({
      count = number
      type  = string
    }))
    labels       = optional(map(string), {})
    machine_type = optional(string)
    advanced_machine_features = object({
      enable_nested_virtualization = optional(bool)
      threads_per_core             = optional(number)
      turbo_mode                   = optional(string)
      visible_core_count           = optional(number)
      performance_monitoring_unit  = optional(string)
      enable_uefi_networking       = optional(bool)
    })
    metadata              = optional(map(string), {})
    min_cpu_platform      = optional(string)
    num_instances         = optional(number, 1)
    on_host_maintenance   = optional(string)
    preemptible           = optional(bool, false)
    region                = optional(string)
    resource_manager_tags = optional(map(string), {})
    service_account = optional(object({
      email  = optional(string)
      scopes = optional(list(string), ["https://www.googleapis.com/auth/cloud-platform"])
    }))
    shielded_instance_config = optional(object({
      enable_integrity_monitoring = optional(bool, true)
      enable_secure_boot          = optional(bool, true)
      enable_vtpm                 = optional(bool, true)
    }))
    source_image_family                 = optional(string)
    source_image_project                = optional(string)
    source_image                        = optional(string)
    static_ips                          = optional(list(string), [])
    subnetwork                          = string
    spot                                = optional(bool, false)
    tags                                = optional(list(string), [])
    zone                                = optional(string)
    termination_action                  = optional(string)
    disk_encryption_key                 = optional(string)
    disk_encryption_key_service_account = optional(string)
  }))
  default = []
  validation {
    condition     = length(distinct([for x in var.login_nodes : x.group_name])) == length(var.login_nodes)
    error_message = "All login_nodes must have a unique group name."
  }
}

############
# NODESETS #
############
variable "nodeset" {
  description = "Define nodesets, as a list."
  # TODO: remove optional & defaults from fields, since they SHOULD be properly set by nodeset module and not here.
  type = list(object({
    node_count_static      = optional(number, 0)
    node_count_dynamic_max = optional(number, 1)
    node_conf              = optional(map(string), {})
    nodeset_name           = string
    additional_disks = optional(list(object({
      disk_name                  = optional(string)
      device_name                = optional(string)
      disk_size_gb               = optional(number)
      disk_type                  = optional(string)
      disk_labels                = optional(map(string), {})
      auto_delete                = optional(bool, true)
      boot                       = optional(bool, false)
      disk_resource_manager_tags = optional(map(string), {})
    })), [])
    bandwidth_tier                      = optional(string, "platform_default")
    can_ip_forward                      = optional(bool, false)
    disk_auto_delete                    = optional(bool, true)
    disk_labels                         = optional(map(string), {})
    disk_resource_manager_tags          = optional(map(string), {})
    disk_size_gb                        = optional(number)
    disk_type                           = optional(string)
    disk_encryption_key                 = optional(string)
    disk_encryption_key_service_account = optional(string)
    enable_confidential_vm              = optional(bool, false)
    confidential_instance_type          = optional(string)
    enable_placement                    = optional(bool, false)
    placement_max_distance              = optional(number, null)
    enable_oslogin                      = optional(bool, true)
    enable_shielded_vm                  = optional(bool, false)
    enable_maintenance_reservation      = optional(bool, false)
    enable_opportunistic_maintenance    = optional(bool, false)
    gpu = optional(object({
      count = number
      type  = string
    }))
    accelerator_topology = optional(string, null)
    dws_flex = object({
      enabled          = bool
      max_run_duration = number
      use_job_duration = bool
      use_bulk_insert  = bool
    })
    labels       = optional(map(string), {})
    machine_type = optional(string)
    advanced_machine_features = object({
      enable_nested_virtualization = optional(bool)
      threads_per_core             = optional(number)
      turbo_mode                   = optional(string)
      visible_core_count           = optional(number)
      performance_monitoring_unit  = optional(string)
      enable_uefi_networking       = optional(bool)
    })
    maintenance_interval     = optional(string)
    instance_properties_json = string
    metadata                 = optional(map(string), {})
    min_cpu_platform         = optional(string)
    network_tier             = optional(string, "STANDARD")
    network_storage = optional(list(object({
      server_ip             = string
      remote_mount          = string
      local_mount           = string
      fs_type               = string
      mount_options         = string
      client_install_runner = optional(map(string))
      mount_runner          = optional(map(string))
    })), [])
    on_host_maintenance   = optional(string)
    preemptible           = optional(bool, false)
    region                = optional(string)
    resource_manager_tags = optional(map(string), {})
    service_account = optional(object({
      email  = optional(string)
      scopes = optional(list(string), ["https://www.googleapis.com/auth/cloud-platform"])
    }))
    shielded_instance_config = optional(object({
      enable_integrity_monitoring = optional(bool, true)
      enable_secure_boot          = optional(bool, true)
      enable_vtpm                 = optional(bool, true)
    }))
    source_image_family  = optional(string)
    source_image_project = optional(string)
    source_image         = optional(string)
    subnetwork_self_link = string
    additional_networks = optional(list(object({
      network            = string
      subnetwork         = string
      subnetwork_project = string
      network_ip         = string
      nic_type           = string
      stack_type         = string
      queue_count        = number
      access_config = list(object({
        nat_ip       = string
        network_tier = string
      }))
      ipv6_access_config = list(object({
        network_tier = string
      }))
      alias_ip_range = list(object({
        ip_cidr_range         = string
        subnetwork_range_name = string
      }))
    })))
    access_config = optional(list(object({
      nat_ip       = string
      network_tier = string
    })))
    spot               = optional(bool, false)
    tags               = optional(list(string), [])
    termination_action = optional(string)
    reservation_name   = optional(string)
    future_reservation = string
    startup_script = optional(list(object({
      filename = string
    content = string })), [])

    zone_target_shape = string
    zone_policy_allow = set(string)
    zone_policy_deny  = set(string)
  }))
  default = []
}

variable "nodeset_tpu" {
  description = "Define TPU nodesets, as a list."
  type = list(object({
    node_count_static      = optional(number, 0)
    node_count_dynamic_max = optional(number, 5)
    nodeset_name           = string
    enable_public_ip       = optional(bool, false)
    node_type              = string
    accelerator_config = optional(object({
      topology = string
      version  = string
      }), {
      topology = ""
      version  = ""
    })
    tf_version   = string
    preemptible  = optional(bool, false)
    preserve_tpu = optional(bool, false)
    zone         = string
    data_disks   = optional(list(string), [])
    docker_image = optional(string, "")
    network_storage = optional(list(object({
      server_ip             = string
      remote_mount          = string
      local_mount           = string
      fs_type               = string
      mount_options         = string
      client_install_runner = optional(map(string))
      mount_runner          = optional(map(string))
    })), [])
    subnetwork = string
    service_account = optional(object({
      email  = optional(string)
      scopes = optional(list(string), ["https://www.googleapis.com/auth/cloud-platform"])
    }))
    project_id = string
    reserved   = optional(string, false)
  }))
  default = []
}


variable "nodeset_dyn" {
  description = "Defines dynamic nodesets, as a list."
  type = list(object({
    nodeset_name    = string
    nodeset_feature = string
  }))
  default = []
}

#############
# PARTITION #
#############
variable "partitions" {
  description = <<EOD
Cluster partitions as a list. See module slurm_partition.
EOD
  type = list(object({
    partition_name        = string
    partition_conf        = optional(map(string), {})
    partition_nodeset     = optional(list(string), [])
    partition_nodeset_dyn = optional(list(string), [])
    partition_nodeset_tpu = optional(list(string), [])
    enable_job_exclusive  = optional(bool, false)
  }))

  default = []

  validation {
    condition     = length(distinct([for x in var.partitions : x.partition_name])) == length(var.partitions)
    error_message = "All partitions must have a unique partition_name."
  }
}

#########
# SLURM #
#########

variable "controller_state_disk" {
  description = <<EOD
  A disk that will be attached to the controller instance template to save state of slurm. The disk is created and used by default.
  To disable this feature, set this variable to null.

  NOTE: This will not save the contents at /opt/apps and /home. To preserve those, they must be saved externally.
  EOD
  type = object({
    type = string
    size = number
  })

  default = {
    type = "pd-ssd"
    size = 50
  }
}

variable "enable_debug_logging" {
  type        = bool
  description = "Enables debug logging mode."
  default     = false
}

variable "extra_logging_flags" {
  type        = map(bool)
  description = "The only available flag is `trace_api`"
  default     = {}
}

variable "enable_cleanup_compute" {
  description = <<EOD
Enables automatic cleanup of compute nodes and resource policies (e.g.
placement groups) managed by this module, when cluster is destroyed.

*WARNING*: Toggling this off will impact the running workload.
Deployed compute nodes will be destroyed.
EOD
  type        = bool
  default     = true
}

variable "enable_bigquery_load" {
  description = <<EOD
Enables loading of cluster job usage into big query.

NOTE: Requires Google Bigquery API.
EOD
  type        = bool
  default     = false
}

variable "enable_slurm_auth" {
  description = <<EOD
Enables slurm authentication instead of munge.

EOD
  type        = bool
  default     = false
}

variable "cloud_parameters" {
  description = "cloud.conf options. Defaults inherited from [Slurm GCP repo](https://github.com/GoogleCloudPlatform/slurm-gcp/blob/master/terraform/slurm_cluster/modules/slurm_files/README_TF.md#input_cloud_parameters)"
  type = object({
    no_comma_params         = optional(bool, false)
    private_data            = optional(list(string))
    scheduler_parameters    = optional(list(string))
    resume_rate             = optional(number)
    resume_timeout          = optional(number)
    suspend_rate            = optional(number)
    suspend_timeout         = optional(number)
    slurmd_timeout          = optional(number)
    unkillable_step_timeout = optional(number)
    topology_plugin         = optional(string)
    topology_param          = optional(string)
    tree_width              = optional(number)
    prolog_flags            = optional(string)
    switch_type             = optional(string)
  })
  default  = {}
  nullable = false
}

variable "enable_default_mounts" {
  description = <<-EOD
    Enable default global network storage from the controller
    - /home
    - /opt/apps
    EOD
  type        = bool
  default     = true
}

variable "network_storage" {
  description = "An array of network attached storage mounts to be configured on all instances."
  type = list(object({
    server_ip             = string,
    remote_mount          = string,
    local_mount           = string,
    fs_type               = string,
    mount_options         = string,
    client_install_runner = optional(map(string))
    mount_runner          = optional(map(string))
  }))
  default = []
}

variable "login_network_storage" {
  description = "An array of network attached storage mounts to be configured on all login nodes."
  type = list(object({
    server_ip     = string,
    remote_mount  = string,
    local_mount   = string,
    fs_type       = string,
    mount_options = string,
  }))
  default = []
}

variable "slurmdbd_conf_tpl" {
  description = "Slurm slurmdbd.conf template file path."
  type        = string
  default     = null
}

variable "slurm_conf_tpl" {
  type        = string
  description = "Slurm slurm.conf template file path. This path is used only if raw content is not provided in 'slurm_conf_template'."
  default     = null
}

variable "slurm_conf_template" {
  description = "Slurm slurm.conf template. Content of the file in 'slurm_conf_tpl' is used if this is not set."
  type        = string
  default     = null
}

variable "cgroup_conf_tpl" {
  description = "Slurm cgroup.conf template file path."
  type        = string
  default     = null
}

variable "controller_startup_script" {
  description = "Startup script used by the controller VM."
  type        = string
  default     = "# no-op"
}

variable "controller_startup_scripts_timeout" {
  description = <<EOD
The timeout (seconds) applied to each script in controller_startup_scripts. If
any script exceeds this timeout, then the instance setup process is considered
failed and handled accordingly.

NOTE: When set to 0, the timeout is considered infinite and thus disabled.
EOD
  type        = number
  default     = 300
}

variable "login_startup_script" {
  description = "Startup script used by the login VMs."
  type        = string
  default     = "# no-op"
}

variable "login_startup_scripts_timeout" {
  description = <<EOD
The timeout (seconds) applied to each script in login_startup_scripts. If
any script exceeds this timeout, then the instance setup process is considered
failed and handled accordingly.

NOTE: When set to 0, the timeout is considered infinite and thus disabled.
EOD
  type        = number
  default     = 300
}

variable "compute_startup_scripts_timeout" {
  description = <<EOD
The timeout (seconds) applied to each startup script in compute nodes. If
any script exceeds this timeout, then the instance setup process is considered
failed and handled accordingly.

NOTE: When set to 0, the timeout is considered infinite and thus disabled.
EOD
  type        = number
  default     = 300
}

variable "enable_chs_gpu_health_check_prolog" {
  description = <<EOD
Enable a Cluster Health Sacnner(CHS) GPU health check that slurmd executes as a prolog script whenever it is asked to run a job step from a new job allocation. Compute nodes that fail GPU health check during prolog will be marked as drained. Find more details at:
https://github.com/GoogleCloudPlatform/cluster-toolkit/tree/main/docs/CHS-Slurm.md
EOD
  type        = bool
  default     = false
  nullable    = false
}

variable "enable_chs_gpu_health_check_epilog" {
  description = <<EOD
Enable a Cluster Health Sacnner(CHS) GPU health check that slurmd executes as an epilog script after completing a job step from a new job allocation.
Compute nodes that fail GPU health check during epilog will be marked as drained. Find more details at:
https://github.com/GoogleCloudPlatform/cluster-toolkit/tree/main/docs/CHS-Slurm.md
EOD
  type        = bool
  default     = false
  nullable    = false
}

variable "prolog_scripts" {
  description = <<EOD
List of scripts to be used for Prolog. Programs for the slurmd to execute
whenever it is asked to run a job step from a new job allocation.
See https://slurm.schedmd.com/slurm.conf.html#OPT_Prolog.
EOD
  type = list(object({
    filename = string
    content  = optional(string)
    source   = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for script in var.prolog_scripts :
      (script.content != null && script.source == null) ||
      (script.content == null && script.source != null)
    ])
    error_message = "Either 'content' or 'source' must be defined, but not both."
  }
}

variable "epilog_scripts" {
  description = <<EOD
List of scripts to be used for Epilog. Programs for the slurmd to execute
on every node when a user's job completes.
See https://slurm.schedmd.com/slurm.conf.html#OPT_Epilog.
EOD
  type = list(object({
    filename = string
    content  = optional(string)
    source   = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for script in var.epilog_scripts :
      (script.content != null && script.source == null) ||
      (script.content == null && script.source != null)
    ])
    error_message = "Either 'content' or 'source' must be defined, but not both."
  }
}

variable "task_prolog_scripts" {
  description = <<EOD
List of scripts to be used for TaskProlog. Programs for the slurmd to execute
as the slurm job's owner prior to initiation of each task.
See https://slurm.schedmd.com/slurm.conf.html#OPT_TaskProlog.
EOD
  type = list(object({
    filename = string
    content  = optional(string)
    source   = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for script in var.task_prolog_scripts :
      (script.content != null && script.source == null) ||
      (script.content == null && script.source != null)
    ])
    error_message = "Either 'content' or 'source' must be defined, but not both."
  }
}

variable "task_epilog_scripts" {
  description = <<EOD
List of scripts to be used for TaskEpilog. Programs for the slurmd to execute
as the slurm job's owner after termination of each task.
See https://slurm.schedmd.com/slurm.conf.html#OPT_TaskEpilog.
EOD
  type = list(object({
    filename = string
    content  = optional(string)
    source   = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for script in var.task_epilog_scripts :
      (script.content != null && script.source == null) ||
      (script.content == null && script.source != null)
    ])
    error_message = "Either 'content' or 'source' must be defined, but not both."
  }
}

variable "enable_external_prolog_epilog" {
  description = <<EOD
Automatically enable a script that will execute prolog and epilog scripts
shared by NFS from the controller to compute nodes. Find more details at:
https://github.com/GoogleCloudPlatform/slurm-gcp/blob/master/tools/prologs-epilogs/README.md
EOD
  type        = bool
  default     = null
}

variable "cloudsql" {
  description = <<EOD
Use this database instead of the one on the controller.
  server_ip : Address of the database server.
  user      : The user to access the database as.
  password  : The password, given the user, to access the given database. (sensitive)
  db_name   : The database to access.
  user_managed_replication : The list of location and (optional) kms_key_name for secret
EOD
  type = object({
    server_ip = string
    user      = string
    password  = string # sensitive
    db_name   = string
    user_managed_replication = optional(list(object({
      location     = string
      kms_key_name = optional(string)
    })), [])
  })
  default   = null
  sensitive = true
}

variable "universe_domain" {
  description = "Domain address for alternate API universe"
  type        = string
  default     = "googleapis.com"
  nullable    = false
}

variable "endpoint_versions" {
  description = "Version of the API to use (The compute service is the only API currently supported)"
  type = object({
    compute = string
  })
  default = {
    compute = "beta"
  }
  nullable = false
}

variable "gcloud_path_override" {
  description = "Directory of the gcloud executable to be used during cleanup"
  type        = string
  default     = ""
  nullable    = false
}

# DEPRECATED VARIABLES

variable "enable_devel" { # tflint-ignore: terraform_unused_declarations
  description = "DEPRECATED: `enable_devel` is always on."
  type        = bool
  default     = null
  validation {
    condition     = var.enable_devel == null
    error_message = "DEPRECATED: It is always on, remove `enable_devel` variable."
  }
}

variable "disable_default_mounts" { # tflint-ignore: terraform_unused_declarations
  description = "DEPRECATED: Use `enable_default_mounts` instead."
  type        = bool
  default     = null
  validation {
    condition     = var.disable_default_mounts == null
    error_message = "DEPRECATED: Use `enable_default_mounts` instead."
  }
}

variable "enable_slurm_gcp_plugins" { # tflint-ignore: terraform_unused_declarations
  description = <<EOD
DEPRECATED: Slurm GCP plugins have been deprecated.
Instead of 'max_hops' plugin please use the 'placement_max_distance' nodeset property.
Instead of 'enable_vpmu' plugin please use 'advanced_machine_features.performance_monitoring_unit' nodeset property.
EOD
  type        = any
  default     = null

  validation {
    condition     = var.enable_slurm_gcp_plugins == null
    error_message = <<EOD
DEPRECATED: Slurm GCP plugins have been deprecated.
Instead of 'max_hops' plugin please use the 'placement_max_distance' nodeset property.
Instead of 'enable_vpmu' plugin please use 'advanced_machine_features.performance_monitoring_unit' nodeset property.
EOD
  }
}


variable "compute_startup_script" { # tflint-ignore: terraform_unused_declarations
  description = <<EOD
DEPRECATED: `compute_startup_script` has been deprecated.
Use `startup_script` of nodeset module instead.
EOD
  type        = any
  default     = null

  validation {
    condition     = var.compute_startup_script == null
    error_message = <<EOD
DEPRECATED: `compute_startup_script` has been deprecated.
Use `startup_script` of nodeset module instead.
EOD
  }
}

variable "slurm_bucket_kms_key" {
  description = "Customer-managed encryption key self-link to use for the Slurm configuration bucket."
  type        = string
  default     = null
}
