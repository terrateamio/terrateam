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

variable "bucket_name" {
  description = <<-EOD
    Name of GCS bucket to use.
  EOD
  type        = string
}

variable "bucket_dir" {
  description = "Bucket directory for cluster files to be put into."
  type        = string
  default     = null
}

variable "enable_debug_logging" {
  type        = bool
  description = "Enables debug logging mode. Not for production use."
  default     = false
}

variable "extra_logging_flags" {
  type        = map(bool)
  description = "The only available flag is `trace_api`"
  default     = {}
}

variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "enable_slurm_auth" {
  description = <<EOD
Enables slurm authentication instead of munge.

EOD
  type        = bool
  default     = false
}

#########
# SLURM #
#########

variable "slurm_cluster_name" {
  type        = string
  description = "The cluster name, used for resource naming and slurm accounting."

  validation {
    condition     = can(regex("^[a-z]([-a-z0-9]{0,19})$", var.slurm_cluster_name))
    error_message = "Variable 'slurm_cluster_name' must be a match of regex '^[a-z]([-a-z0-9]{0,19})$'."
  }
}

variable "controller_state_disk" {
  description = <<EOD
  A disk that will be attached to the controller instance template to save state of slurm. The disk is created and used by default.
  To disable this feature, set this variable to null.

  NOTE: This will not save the contents at /opt/apps and /home. To preserve those, they must be saved externally.
  EOD
  type = object({
    device_name = string
  })

  default = {
    device_name = null
  }
}

variable "enable_bigquery_load" {
  description = <<EOD
Enables loading of cluster job usage into big query.

NOTE: Requires Google Bigquery API.
EOD
  type        = bool
  default     = false
}

variable "slurmdbd_conf_tpl" {
  type        = string
  description = "Slurm slurmdbd.conf template file path."
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
  type        = string
  description = "Slurm cgroup.conf template file path."
  default     = null
}

variable "cloudsql_secret" {
  description = "Secret URI to cloudsql secret."
  type        = string
  default     = null
}

variable "controller_startup_scripts" {
  description = "List of scripts to be ran on controller VM startup."
  type = list(object({
    filename = string
    content  = string
  }))
  default = []
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

variable "nodeset_startup_scripts" {
  description = "List of scripts to be ran on compute VM startup in the specific nodeset."
  type = map(list(object({
    filename = string
    content  = string
  })))
  default = {}
}

variable "compute_startup_scripts_timeout" {
  description = <<EOD
The timeout (seconds) applied to each script in compute_startup_scripts. If
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
https://github.com/GoogleCloudPlatform/slurm-gcp/blob/v5/tools/prologs-epilogs/README.md
EOD
  type        = bool
  default     = false
  nullable    = false
}

variable "disable_default_mounts" {
  description = <<-EOD
    Disable default global network storage from the controller
    - /home
    - /apps
    EOD
  type        = bool
  default     = false
}

variable "network_storage" {
  description = <<EOD
Storage to mounted on all instances.
- server_ip     : Address of the storage server.
- remote_mount  : The location in the remote instance filesystem to mount from.
- local_mount   : The location on the instance filesystem to mount to.
- fs_type       : Filesystem type (e.g. "nfs").
- mount_options : Options to mount with.
EOD
  type = list(object({
    server_ip     = string
    remote_mount  = string
    local_mount   = string
    fs_type       = string
    mount_options = string
  }))
  default = []
}

variable "nodeset" {
  description = "Cluster nodenets, as a list."
  type        = list(any)
  default     = []
}

variable "nodeset_dyn" {
  description = "Cluster nodenets (dynamic), as a list."
  type        = list(any)
  default     = []
}

variable "nodeset_tpu" {
  description = "Cluster nodenets (TPU), as a list."
  type        = list(any)
  default     = []
}

variable "cloud_parameters" {
  description = "cloud.conf options. Default behavior defined in scripts/conf.py"
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

##########
# HYBRID #
##########

variable "enable_hybrid" {
  description = <<EOD
Enables use of hybrid controller mode. When true, controller_hybrid_config will
be used instead of controller_instance_config and will disable login instances.
EOD
  type        = bool
  default     = false
}

variable "google_app_cred_path" {
  type        = string
  description = "Path to Google Application Credentials."
  default     = null
}

variable "slurm_bin_dir" {
  type        = string
  description = <<EOD
Path to directory of Slurm binary commands (e.g. scontrol, sinfo). If 'null',
then it will be assumed that binaries are in $PATH.
EOD
  default     = null
}

variable "slurm_log_dir" {
  type        = string
  description = "Directory where Slurm logs to."
  default     = "/var/log/slurm"
}

variable "slurm_control_host" {
  type        = string
  description = <<EOD
The short, or long, hostname of the machine where Slurm control daemon is
executed (i.e. the name returned by the command "hostname -s").

This value is passed to slurm.conf such that:
SlurmctldHost={var.slurm_control_host}\({var.slurm_control_addr}\)

See https://slurm.schedmd.com/slurm.conf.html#OPT_SlurmctldHost
EOD
  default     = null
}

variable "slurm_control_host_port" {
  type        = string
  description = <<EOD
The port number that the Slurm controller, slurmctld, listens to for work.

See https://slurm.schedmd.com/slurm.conf.html#OPT_SlurmctldPort
EOD
  default     = "6818"
}

variable "slurm_control_addr" {
  type        = string
  description = <<EOD
The IP address or a name by which the address can be identified.

This value is passed to slurm.conf such that:
SlurmctldHost={var.slurm_control_host}\({var.slurm_control_addr}\)

See https://slurm.schedmd.com/slurm.conf.html#OPT_SlurmctldHost
EOD
  default     = null
}

variable "output_dir" {
  type        = string
  description = <<EOD
Directory where this module will write its files to. These files include:
cloud.conf; cloud_gres.conf; config.yaml; resume.py; suspend.py; and util.py.
EOD
  default     = null
}

variable "install_dir" {
  type        = string
  description = <<EOD
Directory where the hybrid configuration directory will be installed on the
on-premise controller (e.g. /etc/slurm/hybrid). This updates the prefix path
for the resume and suspend scripts in the generated `cloud.conf` file.

This variable should be used when the TerraformHost and the SlurmctldHost
are different.

This will default to var.output_dir if null.
EOD
  default     = null
}

variable "munge_mount" {
  description = <<-EOD
  Remote munge mount for compute and login nodes to acquire the munge.key.
  By default, the munge mount server will be assumed to be the
  `var.slurm_control_host` (or `var.slurm_control_addr` if non-null) when
  `server_ip=null`.
  EOD
  type = object({
    server_ip     = string
    remote_mount  = string
    fs_type       = string
    mount_options = string
  })
  default = {
    server_ip     = null
    remote_mount  = "/etc/munge/"
    fs_type       = "nfs"
    mount_options = ""
  }
}

variable "slurm_key_mount" {
  description = <<-EOD
  Remote mount for compute and login nodes to acquire the slurm.key.
  EOD
  type = object({
    server_ip     = string
    remote_mount  = string
    fs_type       = string
    mount_options = string
  })
  default = null
}

variable "endpoint_versions" {
  description = "Version of the API to use (The compute service is the only API currently supported)"
  type = object({
    compute = string
  })
  default = {
    compute = null
  }
}

variable "controller_network_attachment" {
  description = "SelfLink for NetworkAttachment to be attached to the controller, if any."
  type        = string
  default     = null
}
