output "vm_kali_private_ip" {
  value = (azurerm_linux_virtual_machine
            .vm_kali
            .private_ip_address)
}

output "vm_kali_public_ip" {
  value = (azurerm_linux_virtual_machine
            .vm_kali
            .public_ip_address)
}