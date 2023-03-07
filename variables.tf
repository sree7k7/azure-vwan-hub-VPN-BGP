variable "resource_group_location" {
  default     = "northeurope"
}

variable "resource_group_name_prefix" {
  default     = "vwan2-rg"
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
variable "hub_address_space" {
  default = "10.5.0.0/23"
}

# local/destination network i,e simulated network site details. Change details.
variable "vpn_gateway_pip" {
  default = "20.219.46.19"
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