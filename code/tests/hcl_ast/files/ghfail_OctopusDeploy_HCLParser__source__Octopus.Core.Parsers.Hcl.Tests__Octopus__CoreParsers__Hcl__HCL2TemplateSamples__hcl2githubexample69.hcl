provider "google" {
  version     = "2.6"
  credentials = "${file(var.credentials_file)}"
  region      = "${var.region}"
}

resource "google_container_cluster" "jemo-cluster" {
  name               = "${var.cluster_name}"
  location           = "${var.region}"
  initial_node_count = "${var.gcp_cluster_count}"
  project            = "${var.project_id}"

  master_auth {
    username = ""
    password = ""
  }

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    metadata {
      disable-legacy-endpoints = "true"
    }

    labels = {
      foo = "bar"
    }

    tags = [
      "foo",
      "bar"]
  }

  timeouts {
    create = "30m"
    update = "40m"
  }

}


output "client_certificate" {
  value = "${google_container_cluster.jemo-cluster.master_auth.0.client_certificate}"
}

output "client_key" {
  value = "${google_container_cluster.jemo-cluster.master_auth.0.client_key}"
}

output "cluster_ca_certificate" {
  value = "${google_container_cluster.jemo-cluster.master_auth.0.cluster_ca_certificate}"
}


output "gcp_cluster_endpoint" {
  value = "${google_container_cluster.jemo-cluster.endpoint}"
}

output "gcp_cluster_name" {
  value = "${google_container_cluster.jemo-cluster.name}"
}