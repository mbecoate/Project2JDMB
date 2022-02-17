resource "azurerm_resource_group" "RG" {
  name     = var.rg_name
  location = var.location
}

#VNet1

resource "azurerm_virtual_network" "Vnet1" {
  name                = var.Vnet1network_name
  address_space       = var.address_space
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
}

resource "azurerm_subnet" "VNet1Subnet" {
  name                 = var.V1subnet1
  resource_group_name  = azurerm_resource_group.RG.name
  virtual_network_name = azurerm_virtual_network.Vnet1.name
  address_prefixes     = var.V1subnet_address
}

resource "azurerm_subnet" "Bastionsubnet" {
  name                 = var.V1Bastionsubnet
  resource_group_name  = azurerm_resource_group.RG.name
  virtual_network_name = azurerm_virtual_network.Vnet1.name
  address_prefixes     = var.V1Bastionsubnet2_address
}

