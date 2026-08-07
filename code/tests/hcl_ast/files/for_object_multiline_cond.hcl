output "fluent_bit_package_download_commands" {
  value = {
    for forwarder_name, forwarder_config in var.fluent_bit_forwarders
    : forwarder_name
    => forwarder_config.os == "windows" ? module.windows_forwarder_package[forwarder_name].fluent_bit_package_download_command
    : module.linux_forwarder_package[forwarder_name].fluent_bit_package_download_command
  }
}

output "ca_loadbalancer_certs" {
  value = {
    for forwarder_name, forwarder_config in var.fluent_bit_forwarders
    : forwarder_name
    => forwarder_config.os == "windows" ? module.windows_forwarder_package[forwarder_name].ca_loadbalancer_cert
    : module.linux_forwarder_package[forwarder_name].ca_loadbalancer_cert
  }
}
