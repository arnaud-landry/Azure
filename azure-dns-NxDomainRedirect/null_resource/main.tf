provider "azurerm" {
  features {}
  subscription_id = "xxxx-xxxx-xxxx-xxxx-xxxx"
  use_cli = true
}

variable "resource_group_name" {
  default = "dnspr-public"
}

data "azurerm_resources" "private_dns_zones" {
  resource_group_name = var.resource_group_name
  type                = "Microsoft.Network/privateDnsZones"
}

# Build a map of zone names
locals {
  dns_zones = {
    for zone in data.azurerm_resources.private_dns_zones.resources :
    zone.name => zone.name
  }
}

# For each zone, fetch VNet links using external + az cli
data "external" "dns_links" {
  for_each = toset(keys(local.dns_zones)) # Convert object keys to a set
  program = [
    "bash", "-c",
    <<-EOT
      az network private-dns link vnet list \
        --resource-group ${var.resource_group_name} \
        --zone-name ${each.key} \
        --query "[].{zone:'${each.key}',name:name}" -o json | jq -c '{items_json: tostring}'
    EOT
  ]
}

# Apply resolution-policy update
resource "null_resource" "update_resolution_policy" {
  for_each = {
    for item in flatten([
      for zone_result in data.external.dns_links :
      [
        for link in jsondecode(zone_result.result.items_json) : { # Use `result` instead of `value`
          key  = "${link.zone}-${link.name}"
          zone = link.zone
          name = link.name
        }
      ]
    ]) : item.key => {
      zone = item.zone
      name = item.name
    }
  }

  provisioner "local-exec" {
    command = <<EOT
      echo "Updating ${each.value.zone}/${each.value.name} to NxDomainRedirect"
      az network private-dns link vnet update \
        --resource-group ${var.resource_group_name} \
        --zone-name ${each.value.zone} \
        --name ${each.value.name} \
        --resolution-policy NxDomainRedirect
    EOT
    interpreter = ["bash", "-c"]
  }
}