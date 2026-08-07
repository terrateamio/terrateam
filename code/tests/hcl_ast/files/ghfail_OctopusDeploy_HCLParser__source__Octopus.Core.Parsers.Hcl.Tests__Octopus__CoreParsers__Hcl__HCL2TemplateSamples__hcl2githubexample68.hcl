variable "region" {
  description = "The GCP region."
  type    = "string"
}

variable "credentials_file" {
  description = "The credentials file."
  type    = "string"
}

variable "project_id" {
  description = "The project id."
  type    = "string"
}

// GCP Variables
variable "gcp_cluster_count" {
  description = "Count of cluster instances to start."
  type = "string"
}

variable "cluster_name" {
  description = "Cluster name for the GCP Cluster."
  type = "string"
}