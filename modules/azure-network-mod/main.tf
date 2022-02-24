
#use this to use variables created in main and not create new ones
data "azurerm_resource_group" "RG" {
  name = var.rg
  location = var.rg
}

#VNet1
resource "azurerm_virtual_network" "Vnet1" {
  name                = var.Vnet1network_name
  address_space       = var.address_space
  location            = var.rg.location
  resource_group_name = azurerm_resource_group.RG.name
}

resource "azurerm_subnet" "Bastionsubnet" {
  name                 = var.V1Bastionsubnet
  resource_group_name  = azurerm_resource_group.RG.name
  virtual_network_name = azurerm_virtual_network.Vnet1.name
  address_prefixes     = var.V1Bastionsubnet1_address
}

resource "azurerm_subnet" "VNet1Subnetweb" {
  name                 = var.v1subnetweb
  resource_group_name  = azurerm_resource_group.RG.name
  virtual_network_name = azurerm_virtual_network.Vnet1.name
  address_prefixes     = var.v1subnetweb_address
}

resource "azurerm_subnet" "VNet1SubnetBusiness" {
  name                 = var.v1subnetbusiness
  resource_group_name  = azurerm_resource_group.RG.name
  virtual_network_name = azurerm_virtual_network.Vnet1.name
  address_prefixes     = var.v1subnetbusiness_address
}

resource "azurerm_subnet" "VNet1subnetsql" {
  name                 = var.v1subnetsql
  resource_group_name  = azurerm_resource_group.RG.name
  virtual_network_name = azurerm_virtual_network.Vnet1.name
  address_prefixes     = var.v1subnetsql_address
}


#VNet2
resource "azurerm_virtual_network" "Vnet2" {
  name                = var.Vnet2network_name
  address_space       = var.address_space2
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
}

resource "azurerm_subnet" "Bastionsubnet2" {
  name                 = var.V2Bastionsubnet
  resource_group_name  = azurerm_resource_group.RG.name
  virtual_network_name = azurerm_virtual_network.Vnet1.name
  address_prefixes     = var.V2Bastionsubnet1_address
}

resource "azurerm_subnet" "VNet2Subnetweb" {
  name                 = var.v2subnetweb
  resource_group_name  = azurerm_resource_group.RG.name
  virtual_network_name = azurerm_virtual_network.Vnet1.name
  address_prefixes     = var.v2subnetweb_address
}

resource "azurerm_subnet" "VNet2SubnetBusiness" {
  name                 = var.v2subnetbusiness
  resource_group_name  = azurerm_resource_group.RG.name
  virtual_network_name = azurerm_virtual_network.Vnet1.name
  address_prefixes     = var.v2subnetbusiness_address
}

resource "azurerm_subnet" "VNet2subnetsql" {
  name                 = var.v2subnetsql
  resource_group_name  = azurerm_resource_group.RG.name
  virtual_network_name = azurerm_virtual_network.Vnet1.name
  address_prefixes     = var.v2subnetsql_address
}


#VNet peering
resource "azurerm_virtual_network_peering" "Vnet1_to_Vnet2" {
  name                         = "${var.Vnet1network_name}-to-${var.Vnet2network_name}"
  resource_group_name          = azurerm_resource_group.RG.name
  virtual_network_name         = azurerm_virtual_network.Vnet1.name
  remote_virtual_network_id    = azurerm_virtual_network.Vnet2.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}
resource "azurerm_virtual_network_peering" "Vnet2-to-Vnet1" {
  name                         = "${var.webserver_VNET_name}-to-${var.DMZ_VNET_name}"
  resource_group_name          = azurerm_resource_group.RG.name
  virtual_network_name         = azurerm_virtual_network.Vnet2.name
  remote_virtual_network_id    = azurerm_virtual_network.Vnet1.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}


