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

# VMSS 
resource "azurerm_virtual_machine_scale_set" "V1VMSSReference" {
  name                = var.Vnet1WebVM
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name


  sku {
    name     = "Standard_F2"
    tier     = "Standard"
    capacity = 3
  }

  storage_profile_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_profile_data_disk {
    lun           = 0
    caching       = "ReadWrite"
    create_option = "Empty"
    disk_size_gb  = 10
  }


# Use Keyvault in this section
  os_profile {
    computer_name_prefix = var.VMComputername
    admin_username       = "azureuser"
    admin_password = ""
  }


  network_profile {
    name    = "terraformnetworkprofile1"
    primary = true

    ip_configuration {
      name                                   = "V1WebIPConfiguration"
      primary                                = true
      subnet_id                              = azurerm_subnet.VNet1Subnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bpepool.id]
      load_balancer_inbound_nat_rules_ids    = [azurerm_lb_nat_pool.lbnatpool.id]
    }
  }

  tags = {
    environment = "JDMB"
  }
}


#We want to make our Load Balancer Internal (Private) to go to our Busines Tier VMSS & SQL Server Always on
resource "azurerm_lb" "V1WebtoBusinessLB" {
  name                = "V1WbLB"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name

  frontend_ip_configuration {
    name                 = "PrivateIPAddress1"
    subnet_id = azurerm_subnet.VNet1Subnet.id
    private_ip_address = "10.0.0.6"
    private_ip_address_allocation = "static"
    private_ip_address_version = "IPv4"
  }
}

resource "azurerm_lb_backend_address_pool" "bpepool" {
  resource_group_name = azurerm_resource_group.RG.name
  loadbalancer_id     = azurerm_lb.V1WebtoBusinessLB.id
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_nat_pool" "lbnatpool" {
  resource_group_name            = azurerm_resource_group.RG.name
  name                           = "ssh"
  loadbalancer_id                = azurerm_lb.V1WebtoBusinessLB.id
  protocol                       = "Tcp"
  frontend_port_start            = 50000
  frontend_port_end              = 50119
  backend_port                   = 22
  frontend_ip_configuration_name = "PrivateIPAddress1"
}

resource "azurerm_lb_probe" "HealthProbe" {
  resource_group_name = azurerm_resource_group.RG.name
  loadbalancer_id     = azurerm_lb.V1WebtoBusinessLB.id
  name                = "http-probe"
  protocol            = "Http"
  request_path        = "/health"
  port                = 80
}
