variable "subscription_id" {
  description = "Target subscription"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group containing the Private DNS zones"
  type        = string
}

variable "dns_zone_links" {
  description = "Map of DNS zones to their VNet links"
  type = map(list(object({
    link_name           = string
    virtual_network_id  = string
  })))
}
