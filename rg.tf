#------------------------------------------------------------
# Resource Group - Create or reference an existing one
#------------------------------------------------------------
resource "azurerm_resource_group" "RG" {
  count = var.create_resource_group ? 1 : 0

  name     = var.resource_group_name
  tags = var.tags
  location = var.location

}

data "azurerm_resource_group" "RG" {
  count = var.create_resource_group ? 0 : 1

  name = var.resource_group_name
}

# Resolve resource group name and location regardless of create/reference mode
locals {
  resource_group_name = var.create_resource_group ? azurerm_resource_group.RG[0].name : data.azurerm_resource_group.RG[0].name
  location            = var.create_resource_group ? azurerm_resource_group.RG[0].location : data.azurerm_resource_group.RG[0].location
}
