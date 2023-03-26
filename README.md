# azure-vwan-hub-VPN-BGP

Enable BGP connection between vhub gateway and local network.

**Note**: You required a simulated corporate network. Please follow [here](https://github.com/sree7k7/tf_vnet_vpn_lgw_bastion), helps on implementing simulated on-prem network.

![diagram](/pics/VWAN-S2S-VPN-BGP.png)
## Prerequsites
- [terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [azure cli](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) & [sign in](https://learn.microsoft.com/en-us/cli/azure/authenticate-azure-cli)

1. You need on-prem: vpn gateway ip, asn, bgp-peer ip, shared-key.
2. Once you have on-prem details, change the below paramter values from *variable.tf* i.e, on-prem vpn gateway shown in below pic.
```terraform
variable "vpn_gateway_pip" {
  default = "20.166.229.221"
  description = "Destination vpn gateway ip i,e on-prem vpn gateway pip"
}
variable "asn" {
  default = "65020"
  description = "vpn gateway asn"
}
variable "bgp_peering_address" {
  default = "10.2.3.254"
  description = "vpn gateway BGP IP Address"
}
variable "shared_key" {
  default = "abc@143"
}

```
![diagram](/pics/on-prem-vpn-gateway.png)
3. execute below cmds:
```terraform 
   terraform init
   terraform plan
   terraform apply
```
> **Note**: If fails, try to execute: **terraform init -upgrade** on terminal and execute cmd: **terraform apply --auto-approve**.

4. Verify the connectivity status at virtual_hub VPN site. Check this by navigating to Virtual WANs → Virtual hub → VPN (Site to site) → vpn Sites → check the site.