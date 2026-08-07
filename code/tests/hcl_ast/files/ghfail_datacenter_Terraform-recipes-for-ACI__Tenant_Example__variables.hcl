# APIC credentials and URL
variable "credentials" {
  type = map(string)
  default = {
    apic_username = "admin"
    apic_password = "password"
    apic_url      = "https://apic-url"
  }
  sensitive = true
}

# Tenant that contains the shared L3out
data "aci_tenant" "common_tenant" {
  name = "common"
}

# VRF that contains the shared L3out
data "aci_vrf" "common_vrf" {
  tenant_dn = data.aci_tenant.common_tenant.id
  name      = "default"
}

# Name of the shared L3out
data "aci_l3_outside" "shared_l3_out" {
  tenant_dn = data.aci_tenant.common_tenant.id
  name      = "internet"
}

# Tenant
variable "tenant" {
  default = "demo"
}

# VRF
variable "vrf" {
  default = "demo.vrf1"
}

# Bridge domains and subnets
variable "bds" {
  default = {
    "192.168.100.0_24" = {
      ip = "192.168.100.1/24"
    },
    "192.168.101.0_24" = {
      ip = "192.168.101.1/24"
    },
    "192.168.102.0_24" = {
      ip = "192.168.102.1/24"
    }
  }
}

# Application Profile
variable "ap" {
  default = "vlans"
}

# Endpoint Groups - Modifying the value of external_access will automatically advertise the BD subnet via the shared L3out
variable "epgs" {
  default = {
    vlan100 = {
      description     = "epg for 192.168.100.0_24"
      ap              = "vlans"
      bd              = "192.168.100.0_24"
      domain          = "phys"
      domain_type     = "phys"
      external_access = true # true | false
    },
    vlan101 = {
      description     = "epg for 192.168.101.0_24"
      ap              = "vlans"
      bd              = "192.168.101.0_24"
      domain          = "phys"
      domain_type     = "phys"
      external_access = false # true | false
    },
    vlan102 = {
      description     = "epg for 192.168.102.0_24"
      ap              = "vlans"
      bd              = "192.168.102.0_24"
      domain          = "phys"
      domain_type     = "phys"
      external_access = false # true | false
    }
  }
}

# Filters
variable "filters" {
  default = {
    tcp_src_any_to_dst_3306 = {
      destination_from_port = "3306"
      destination_to_port   = "3306"
      protocol              = "tcp"
      ether_type            = "ipv4"
    },
    tcp_src_any_to_dst_8080 = {
      destination_from_port = "8080"
      destination_to_port   = "8080"
      protocol              = "tcp"
      ether_type            = "ipv4"
    },
    tcp_src_any_to_dst_6379 = {
      destination_from_port = "6379"
      destination_to_port   = "6379"
      protocol              = "tcp"
      ether_type            = "ipv4"
    },
    icmp_src_any_to_dst_0 = {
      destination_from_port = "0"
      destination_to_port   = "0"
      protocol              = "icmp"
      ether_type            = "ipv4"
    }
  }
}

# Contracts
variable "contracts" {
  default = {
    web_app = {
      subject = "subject1"
      filter  = ["tcp_src_any_to_dst_8080", "icmp_src_any_to_dst_0"]
    },
    cache = {
      subject = "subject1"
      filter  = ["tcp_src_any_to_dst_6379", "icmp_src_any_to_dst_0"]
    },
    sql = {
      subject = "subject1"
      filter  = ["tcp_src_any_to_dst_3306", "icmp_src_any_to_dst_0"]
    }
  }
}

# Contract relations to EPGs
variable "contract_to_epgs" {
  default = {
    web_app = {
      consumer = ""
      provider = "vlan100"
    },
    sql = {
      consumer = "vlan100"
      provider = "vlan101"
    }
    cache = {
      consumer = "vlan101"
      provider = "vlan102"
    }
  }
}

# Static Path bindings
variable "static_paths" {
  default = {
    vlan100_to_leaf_101_1_12 = {
      epg    = "vlan100"
      encap  = "100"
      iftype = "switchport"
      ifmode = "regular"
      pod    = "1"
      leaf   = "101"
      if     = "1/12"
    },
    vlan101_to_leafs_101_102_test_vpc = {
      epg    = "vlan101"
      encap  = "101"
      iftype = "vpc"
      ifmode = "regular"
      pod    = "1"
      leaf   = "101-102"
      if     = "test_vpc"
    }
  }
}