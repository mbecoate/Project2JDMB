
output "Vnet1" {
  description = "The first vnet"
  value = azurerm_virtual_network.Vnet1
  depends_on = [
    azurerm_virtual_network.Vnet1
  ]
}
output "Vnet2" {
  description = "The first vnet"
  value = azurerm_virtual_network.Vnet2
  depends_on = [
    azurerm_virtual_network.Vnet2
  ]
}

output "V1Bastionsubnet1" {
  description = "contains value of bastion1 subnet"
  value = azurerm_subnet.Bastionsubnet1
}
output "V2Bastionsubnet1" {
  description = "contains value of bastion2 subnet"
  value = azurerm_subnet.Bastionsubnet2
}


output "v1subnetbusiness" {
  description = "contains value of business1 subnet"
  value = azurerm_subnet.VNet1SubnetBusiness
}
output "v2subnetbusiness" {
  description = "contains value of business2 subnet"
  value = azurerm_subnet.VNet2SubnetBusiness
}


output "v1subnetsql" {
  description = "contains value of sql1 subnet"
  value = azurerm_subnet.VNet1subnetsql
}
output "v2subnetsql" {
  description = "contains value of sql1 subnet"
  value = azurerm_subnet.VNet2subnetsql
}


output "v1subnetvagfe" {
  description = "contains value of application gateway frontend subnet"
  value = azurerm_subnet.VAG1frontend
}
output "v2subnetvagfe" {
  description = "contains value of application gateway frontend subnet"
  value = azurerm_subnet.VAG2frontend
}


output "v1subnetvagbe" {
  description = "contains value of application gateway backend subnet"
  value = azurerm_subnet.VAG1backend
}
output "v2subnetvagbe" {
  description = "contains value of application gateway backend subnet"
  value = azurerm_subnet.VAG2backend
}




