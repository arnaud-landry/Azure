terraform {
  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = ">=2.4.0"
    }
  }
  required_version = ">= 1.3.0"
}

resource "azapi_resource" "dns_vnet_links" { 
  for_each = {
    for item in flatten([
      for zone, links in var.dns_zone_links : [
        for link in links : {
          key                = "${zone}-${link.link_name}"
          zone               = zone
          link_name          = link.link_name
          virtual_network_id = link.virtual_network_id
        }
      ]
    ]) : item.key => item
  }

  type      = "Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01"
  name      = each.value.link_name
  parent_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Network/privateDnsZones/${each.value.zone}"
  location  = "global"

  body = {
    properties = {
      virtualNetwork = {
        id = each.value.virtual_network_id
      }
      registrationEnabled = false
      resolutionPolicy    = "NxDomainRedirect"
    }
  }
}
