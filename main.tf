
# Create Resource Group
resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = var.resource_group_name_prefix
}

# Create virtual network
resource "azurerm_virtual_network" "vnet_work" {
  name                = var.vnet_config["vnetname"]
  address_space       = var.vnet_cidr
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create public subnet
resource "azurerm_subnet" "vnet_public_subnet" {
  name                 = var.vnet_config["public_subnet"]
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_work.name
  address_prefixes     = var.public_subnet_address
}

# Create private subnet
resource "azurerm_subnet" "vnet_private_subnet" {
  name                 = var.vnet_config["private_subnet"]
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_work.name
  address_prefixes     = var.private_subnet_address
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "public_nsg" {
  name                = "SecurityGroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "InternetAccess"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "RDP"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create public IPs
resource "azurerm_public_ip" "public_ip" {
  name                = "PublicIp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}
# Create network interface
resource "azurerm_network_interface" "public_nic" {
  name                = "NIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "nic_configuration"
    subnet_id                     = azurerm_subnet.vnet_public_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# Associate NSG to public-subnet
resource "azurerm_subnet_network_security_group_association" "public_nsg" {
  subnet_id                 = azurerm_subnet.vnet_public_subnet.id
  network_security_group_id = azurerm_network_security_group.public_nsg.id
}

# Create virtual machine
resource "azurerm_windows_virtual_machine" "vm" {
  name                  = "${var.resource_group_location}-Vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.public_nic.id]
  size                  = "Standard_DS1_v2"
  admin_username                  = "demousr"
  admin_password                  = "Password@123"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "vm_extension_install_iis" {
  name                       = "vm_extension_install_iis"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.9"
  auto_upgrade_minor_version = true
  settings = <<SETTINGS
    {
        "commandToExecute":"powershell -ExecutionPolicy Unrestricted Add-WindowsFeature Web-Server; powershell -ExecutionPolicy Unrestricted Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.html\" -Value $($env:computername)"
    }
SETTINGS
}

# create virtual WAN
resource "azurerm_virtual_wan" "virtual_wan" {
  name                = "virtual-vwan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  type                = "Standard"
  allow_branch_to_branch_traffic = true
}
# create virtual hub
resource "azurerm_virtual_hub" "virtual_hub" {
  name                = "virtual_hub"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  virtual_wan_id      = azurerm_virtual_wan.virtual_wan.id
  sku                = "Standard"
  address_prefix      = var.hub_address_space
}

# Connect Vnet to Virtual hub aka VWAN
resource "azurerm_virtual_hub_connection" "vnet-vhub-connection" {
  name                      = "vnet-vhub-connection"
  virtual_hub_id            = azurerm_virtual_hub.virtual_hub.id
  remote_virtual_network_id = azurerm_virtual_network.vnet_work.id
}

## -- vhub route table
resource "azurerm_virtual_hub_route_table" "vhubroutetable" {
  name           = "vhubroutetable"
  virtual_hub_id = azurerm_virtual_hub.virtual_hub.id
  labels         = ["vhubroutetable"]

  route {
    name              = "vhubroutetable"
    destinations_type = "CIDR"
    destinations      = ["0.0.0.0/0"]
    next_hop_type     = "ResourceId"
    next_hop          = azurerm_virtual_hub_connection.vnet-vhub-connection.id
  }
}

# resource "azurerm_virtual_hub_connection_route_table_association" "example" {
#   virtual_hub_connection_id = azurerm_virtual_hub.virtual_hub.id
#   route_table_id            = azurerm_virtual_hub_route_table.vhubroutetable.id
# }

### --- hub vpn gateway ----

resource "azurerm_vpn_gateway" "vpn_gateway" {
  name                = "vpn_gateway"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  virtual_hub_id      = azurerm_virtual_hub.virtual_hub.id
  bgp_settings {
    asn = 65515
    peer_weight = "50"
  }
  # depends_on = [  ]
}
# vpn site onprem details
resource "azurerm_vpn_site" "vpn_site" {
  name                = "vpn_site"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  virtual_wan_id      = azurerm_virtual_wan.virtual_wan.id
  link {
    name       = "link1"
    ip_address = var.vpn_gateway_pip
    bgp {
      asn        = var.asn
      peering_address = var.bgp_peering_address
    }
    
  }
  # link {
  #   name       = "link2"
  #   ip_address = "20.91.218.15"
  # }
}

resource "azurerm_vpn_gateway_connection" "vpn_gateway_connection" {
  name               = "vpn_gateway_connection"
  vpn_gateway_id     = azurerm_vpn_gateway.vpn_gateway.id
  remote_vpn_site_id = azurerm_vpn_site.vpn_site.id

  vpn_link {
    name             = "link1"
    vpn_site_link_id = azurerm_vpn_site.vpn_site.link[0].id
    bgp_enabled = true
    shared_key = var.shared_key
  }
}


#-----------------
# Azure Firewall, subnet, pip 
#-----------------
resource "azurerm_subnet" "fw-subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_work.name
  address_prefixes     = var.firewall_subnet_address_prefix
  service_endpoints    = var.firewall_service_endpoints
}

resource "azurerm_public_ip" "fw-pip" {
  # for_each            = local.public_ip_map
  name                = "fw_pip"
  location            = var.resource_group_location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  # public_ip_prefix_id = azurerm_public_ip_prefix.pip_prefix.id
}
resource "azurerm_firewall_policy" "firewall_policy" {
  name                = "firewall_policy"
  location            = var.resource_group_location
  resource_group_name = azurerm_resource_group.rg.name
}
resource "azurerm_firewall" "vwan_custom_fw" {
  name                = lower("vwanFW-${var.vnet_config["vnetname"]}-${var.resource_group_location}")
  location            = var.resource_group_location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "AZFW_Hub"
  sku_tier            = "Standard"
  zones               = [1,2,3]
  # threat_intel_mode   = ""
  firewall_policy_id = azurerm_firewall_policy.firewall_policy.id
  virtual_hub {
    virtual_hub_id  = azurerm_virtual_hub.virtual_hub.id
    public_ip_count = 1
  }
}

#----------------------------------------------
# Azure Firewall Network/Application/NAT Rules 
#----------------------------------------------

# resource "azurerm_firewall_application_rule_collection" "app-rc" {
#   name                = "fw-app-rc"
#   azure_firewall_name = azurerm_firewall.vwan_custom_fw.name
#   resource_group_name = azurerm_resource_group.rg.name
#   priority            = 100
#   action              = "Allow"

#   rule {
#     name = "testrule"

#     source_addresses = [
#       "10.0.0.0/16",
#     ]

#     target_fqdns = [
#       "*.google.com",
#     ]

#     protocol {
#       port = "443"
#       type = "Https"
#     }
#   }
# }

resource "azurerm_firewall_nat_rule_collection" "dnatfw_rule" {
  # for_each            = local.fw_nat_rules
  # name                = lower(format("fw-nat-rule-%s-${var.hub_vnet_name}-${local.location}", each.key))
  name                = lower("fw-dnat-rule-${var.vnet_config["vnetname"]}-${var.resource_group_location}")
  azure_firewall_name = azurerm_firewall.vwan_custom_fw.name
  resource_group_name = azurerm_resource_group.rg.name
  priority            = 100
  action              = "Dnat"

  rule {
    name                  = "local-rdp-rule"
    source_addresses      = ["83.221.156.201",]
    destination_ports     = ["4000"]
    destination_addresses = [azurerm_public_ip.fw-pip.ip_address]
    protocols             = ["TCP",]
    translated_address    = azurerm_windows_virtual_machine.vm.private_ip_address
    translated_port       = 3389
  }
}


# # Azure Bastion host
# resource "azurerm_subnet" "AzureBastionSubnet" {
#   name                 = "AzureBastionSubnet"
#   resource_group_name = azurerm_resource_group.rg.name
#   virtual_network_name = azurerm_virtual_network.vnet_work.name
#   address_prefixes     = var.bastion_subnet_address
# }

# resource "azurerm_public_ip" "bastion_pip" {
#   name                = "bastion_pip"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }

# resource "azurerm_bastion_host" "BastionHost" {
#   name                = "BastionHost"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name

#   ip_configuration {
#     name                 = "bastion_pip_config"
#     subnet_id            = azurerm_subnet.AzureBastionSubnet.id
#     public_ip_address_id = azurerm_public_ip.bastion_pip.id
#   }
# }
