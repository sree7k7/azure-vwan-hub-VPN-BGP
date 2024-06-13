variable "resource_group_location" {
  default     = "westeurope"
}

variable "resource_group_name_prefix" {
  default     = "vwanrg"
}

# Vnet details
variable "vnet_config" {
    type = map(string)
    default = {
      vnetname = "CoreServiceNet"
      public_subnet = "PublicSubnet"      
      private_subnet = "PrivateSubnet"       
    }
}
variable "vnet_cidr" {
  default = ["10.7.0.0/16"]
}
variable "public_subnet_address" {
  default = ["10.7.1.0/24"]
}
variable "private_subnet_address" {
  default = ["10.7.2.0/24"]
}
variable "gateway_subnet_address" {
  default = ["10.7.3.0/24"]
}
variable "bastion_subnet_address" {
  default = ["10.7.4.0/25"]
}
variable "firewall_subnet_address_prefix" {
  default = ["10.7.4.128/25"]
}
#

variable "hub_address_space" {
  default = "10.5.0.0/23"
}

# local/destination network i,e simulated network site details.
variable "vpn_gateway_pip" {
  default = "20.204.185.12"
}
variable "asn" {
  default = "65020"
}
variable "bgp_peering_address" {
  default = "10.2.3.254"
}
variable "shared_key" {
  default = "abc@143"
}


### -------
variable "firewall_service_endpoints" {
  description = "Service endpoints to add to the firewall subnet"
  type        = list(string)
  default = [
    "Microsoft.AzureActiveDirectory",
    "Microsoft.AzureCosmosDB",
    "Microsoft.EventHub",
    "Microsoft.KeyVault",
    "Microsoft.ServiceBus",
    "Microsoft.Sql",
    "Microsoft.Storage",
  ]
}