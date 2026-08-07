resource "azurerm_public_ip" "public_ip_attacker" {
  name                = "public-ip-attacker"
  location            = var.rg_location
  resource_group_name = var.rg_name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "nic_attacker" {
  name                = "nic-attacker"
  location            = var.rg_location
  resource_group_name = var.rg_name

  ip_configuration {
    name                          = (
      "nic_configuration_attacker"
    )

    subnet_id                     = var.subnet
    private_ip_address_allocation = "Dynamic"
    
    public_ip_address_id          = (
      azurerm_public_ip.public_ip_attacker.id
    )
  }
}

resource "azurerm_network_interface_security_group_association" "nsg_assoc_attacker" {
  network_interface_id      = (
    azurerm_network_interface
      .nic_attacker
      .id
  )

  network_security_group_id = var.nsg
}

resource "azurerm_network_interface_application_security_group_association" "asg_assoc_3" {
  network_interface_id          = (
    azurerm_network_interface
      .nic_attacker
      .id
  )

  application_security_group_id = var.asg
}

resource "azurerm_linux_virtual_machine" "vm_kali" {
  name                  = "vm-kali"
  location              = var.rg_location
  resource_group_name   = var.rg_name
  size                  = "Standard_DS1_v2"
  network_interface_ids = [
    azurerm_network_interface.nic_attacker.id
  ]

  os_disk {
    name                 = "os-disk-kali"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_id = var.source_image_id

  plan {
    name = "kali"
    publisher = "kali-linux"
    product = "kali"
  }

  computer_name                   = "vm-kali"

  admin_ssh_key {
    username   = "kali_admin"
    public_key = var.my_public_ssh_key
  }
  
  admin_username                  = "kali_admin"
  admin_password                  = "KaliLinux1234!!!"

  disable_password_authentication = false
  
  boot_diagnostics {
    storage_account_uri = null
  }
}