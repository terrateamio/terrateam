locals {
  ipsec_conf = {
    ike                  = var.config.ciphers.ipsec.ike
    esp                  = var.config.ciphers.ipsec.esp
    strongswan_log_level = var.config.strongswan_log_level
    rightsourceip        = ["${cidrhost(var.config.ipsec.ipv4, 2)}-${cidrhost(var.config.ipsec.ipv4, -2)},${cidrhost(var.config.ipsec.ipv6, 2)}-${cidrhost(var.config.ipsec.ipv6, 9223372036854775807)}"]
    rightdns             = var.config.dns.encryption.enabled || var.config.dns.adblocking.enabled ? values(var.config.ipsec_dns) : concat(var.config.dns.resolvers.ipv4, var.ipv6 ? var.config.dns.resolvers.ipv6 : [])
  }

  strongswan = {
    strongswan_conf = file("${path.module}/files/strongswan/strongswan.conf")
    ipsec_conf      = templatefile("${path.module}/files/strongswan/ipsec.conf", { vars = local.ipsec_conf })
    pki             = var.pki
  }
}
