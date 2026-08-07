# Вывод информации внутренним ipv4 хостов в кластере
output "internal_ip_address_app1c-servers" {
  value = [
    for srv in yandex_compute_instance.app1c-server: "HOST: ${srv.name}; IPin:${srv.network_interface.0.ip_address}"
  ]
  }
# Вывод информации по кластеру 1С (имя хоста и его внешний ipv4). Вывод возможен в нескольких форматах
output "ansible_hosts" {
  value = [
    for srv in yandex_compute_instance.app1c-server:
      var.ansible_format_output ? 
      "${srv.hostname} ansible_host=${srv.network_interface.0.nat_ip_address}" : 
      "HOST:${srv.hostname}; IP:${srv.network_interface.0.nat_ip_address}"
  ]
}