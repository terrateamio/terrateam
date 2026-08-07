
# Generate /etc/hosts files
locals {
    all_ips = "${concat(
        "${list(module.infrastructure.bastion_private_ip)}",
        "${module.infrastructure.master_private_ip}",
        "${module.infrastructure.infra_private_ip}",
        "${module.infrastructure.worker_private_ip}",
        "${module.infrastructure.storage_private_ip}",
        "${list(module.console_loadbalancer.node_private_ip)}",
        "${list(module.app_loadbalancer.node_private_ip)}"
    )}"
    all_hostnames = "${concat(
        "${list(module.infrastructure.bastion_hostname)}",
        "${module.infrastructure.master_hostname}",
        "${module.infrastructure.infra_hostname}",
        "${module.infrastructure.worker_hostname}",
        "${module.infrastructure.storage_hostname}",
        "${list(module.console_loadbalancer.node_hostname)}",
        "${list(module.app_loadbalancer.node_hostname)}"
    )}"

    all_count = "${
      lookup(var.bastion, "nodes", "1") + 
      lookup(var.master, "nodes", "1") + 
      lookup(var.infra, "nodes", "1") + 
      lookup(var.worker, "nodes", "3") + 
      lookup(var.storage, "nodes", "3") +
      1 + // console load balancer
      1   // app load balancer
    }"
}

module "etchosts" {
  source = "github.com/ibm-cloud-architecture/terraform-dns-etc-hosts.git"

  dependson = [
    "${module.rhnregister.registered_resource}",
  ]

  bastion_ip_address      = "${module.infrastructure.bastion_public_ip}"
  bastion_ssh_user        = "${var.ssh_user}"
  bastion_ssh_password    = "${var.ssh_password}"
  bastion_ssh_private_key = "${file(var.ssh_private_key_file)}"

  ssh_user           = "${var.ssh_user}"
  ssh_password       = "${var.ssh_password}"
  ssh_private_key    = "${tls_private_key.installkey.private_key_pem}"
  
  node_ips                = "${local.all_ips}"
  node_hostnames          = "${local.all_hostnames}"
  domain                  = "${var.private_domain}"

  num_nodes = "${local.all_count}"
}

#module "dns_private" {
#    source                  = "github.com/ibm-cloud-architecture/terraform-dns-rfc2136"
#
#    node_count = "${lookup(var.bastion, "nodes", "1") + 
#      lookup(var.master, "nodes", "1") + 
#      lookup(var.worker, "nodes", "3") + 
#      lookup(var.infra, "nodes", "1") + 
#      lookup(var.storage, "nodes", "3") +
#      1 +
#      1}"
#
#    node_hostnames = concat(
#            list(module.infrastructure.bastion_hostname),
#            module.infrastructure.master_hostname,
#            module.infrastructure.worker_hostname,
#            module.infrastructure.infra_hostname,
#            module.infrastructure.storage_hostname,
#            list(module.console_loadbalancer.node_hostname),
#            list(module.app_loadbalancer.node_hostname))
#
#    node_ips = concat(
#            list(module.infrastructure.bastion_private_ip),
#            module.infrastructure.master_private_ip,
#            module.infrastructure.worker_private_ip,
#            module.infrastructure.infra_private_ip,
#            module.infrastructure.storage_private_ip,
#            list(module.console_loadbalancer.node_private_ip),
#            list(module.app_loadbalancer.node_private_ip))
#
#    zone_name               = "${var.private_domain}."
#    dns_server              = "${element(var.private_dns_servers, 0)}"
#
#    create_node_ptr_records = true
#
#    key_name = "${var.dns_key_name}"
#    key_algorithm = "${var.dns_key_algorithm}"
#    key_secret = "${var.dns_key_secret}"
#    record_ttl = "${var.dns_record_ttl}" 
#}
#
#
##module "dns_public" {
##    source                  = "github.com/ibm-cloud-architecture/terraform-dns-cloudflare"
##
##    cloudflare_email         = "${var.cloudflare_email}"
##    cloudflare_token         = "${var.cloudflare_token}"
##    cloudflare_zone          = "${var.cloudflare_zone}"
##
##    num_cnames = 2
##    cnames = "${zipmap(
##        concat(
##            list("${var.master_cname}"),
##            list("*.${var.app_cname}")
##        ),
##        concat(
##            list("${module.console_loadbalancer.node_hostname}.${var.private_domain}"),
##            list("${module.app_loadbalancer.node_hostname}.${var.private_domain}")
##        )
##    )}"
##}
