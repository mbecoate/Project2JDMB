

#VNet1
resource "azurerm_virtual_network" "Vnet1" {
  name                = var.Vnet1network_name
  address_space       = var.address_space
  location            = var.vnet1location
  resource_group_name = var.rg
  tags = var.tags
}
resource "azurerm_subnet" "Bastionsubnet1" {
  name                 = var.V1Bastionsubnet
  resource_group_name  = var.rg
  virtual_network_name = azurerm_virtual_network.Vnet1.name
  address_prefixes     = var.V1Bastionsubnet1_address
  service_endpoints = ["Microsoft.Sql"]
}
resource "azurerm_subnet" "VNet1SubnetBusiness" {
  name                 = var.v1subnetbusiness
  resource_group_name  = var.rg
  virtual_network_name = azurerm_virtual_network.Vnet1.name
  address_prefixes     = var.v1subnetbusiness_address
  service_endpoints = ["Microsoft.Sql"]
}
resource "azurerm_subnet" "VNet1subnetsql" {
  name                 = var.v1subnetsql
  resource_group_name  = var.rg
  virtual_network_name = azurerm_virtual_network.Vnet1.name
  address_prefixes     = var.v1subnetsql_address
  service_endpoints = ["Microsoft.Sql"]
}
resource "azurerm_subnet" "VAG1frontend" {
  name                 = "VAG1frontend"
  resource_group_name  = var.rg
  virtual_network_name = azurerm_virtual_network.Vnet1.name
  address_prefixes     = var.v1fesubnetVAG_address
  service_endpoints = ["Microsoft.Sql"]
}
resource "azurerm_subnet" "VAG1backend" {
  name                 = "VAG1backend"
  resource_group_name  = var.rg
  virtual_network_name = azurerm_virtual_network.Vnet1.name
  address_prefixes     = var.v1besubnetVAG_address
  service_endpoints = ["Microsoft.Sql"]
}



#VNet2
resource "azurerm_virtual_network" "Vnet2" {
  name                = var.Vnet2network_name
  address_space       = var.address_space2
  location            = var.vnet2location
  resource_group_name = var.rg
  tags = var.tags
}
resource "azurerm_subnet" "Bastionsubnet2" {
  name                 = var.V2Bastionsubnet
  resource_group_name  = var.rg
  virtual_network_name = azurerm_virtual_network.Vnet2.name
  address_prefixes     = var.V2Bastionsubnet1_address
  service_endpoints = ["Microsoft.Sql"]
}
resource "azurerm_subnet" "VNet2SubnetBusiness" {
  name                 = var.v2subnetbusiness
  resource_group_name  = var.rg
  virtual_network_name = azurerm_virtual_network.Vnet2.name
  address_prefixes     = var.v2subnetbusiness_address
  service_endpoints = ["Microsoft.Sql"]
}
resource "azurerm_subnet" "VNet2subnetsql" {
  name                 = var.v2subnetsql
  resource_group_name  = var.rg
  virtual_network_name = azurerm_virtual_network.Vnet2.name
  address_prefixes     = var.v2subnetsql_address
  service_endpoints = ["Microsoft.Sql"]
}
resource "azurerm_subnet" "VAG2frontend" {
  name                 = "VAG2frontend"
  resource_group_name  = var.rg
  virtual_network_name = azurerm_virtual_network.Vnet2.name
  address_prefixes     = var.v2fesubnetVAG_address
  service_endpoints = ["Microsoft.Sql"]
}
resource "azurerm_subnet" "VAG2backend" {
  name                 = "VAG2backend"
  resource_group_name  = var.rg
  virtual_network_name = azurerm_virtual_network.Vnet2.name
  address_prefixes     = var.v2besubnetVAG_address
  service_endpoints = ["Microsoft.Sql"]
}




#VNet peering
resource "azurerm_virtual_network_peering" "Vnet1_to_Vnet2" {
  name                         = "${azurerm_virtual_network.Vnet1.name}-to-${azurerm_virtual_network.Vnet2.name}"
  resource_group_name          = var.rg
  virtual_network_name         = azurerm_virtual_network.Vnet1.name
  remote_virtual_network_id    = azurerm_virtual_network.Vnet2.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  depends_on = [
    azurerm_virtual_network.Vnet1, azurerm_virtual_network.Vnet2
  ]
}
resource "azurerm_virtual_network_peering" "Vnet2-to-Vnet1" {
  name                         = "${azurerm_virtual_network.Vnet2.name}-to-${azurerm_virtual_network.Vnet1.name}"
  resource_group_name          = var.rg
  virtual_network_name         = azurerm_virtual_network.Vnet2.name
  remote_virtual_network_id    = azurerm_virtual_network.Vnet1.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  depends_on = [
    azurerm_virtual_network.Vnet1, azurerm_virtual_network.Vnet2
  ]
}


