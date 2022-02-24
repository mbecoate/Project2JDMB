resource "azurerm_resource_group" "RG" {
  name     = var.rg_name
  location = var.location
  tags = var.tags
}



#----------------
#call vnet module
#----------------
module "Network" {
  source = "./modules/azure-network-mod"
  rg = var.rg_name
  #use default settings of network
  tags = var.tags
}


#traffic manager

resource "azurerm_traffic_manager_profile" "t8p2-tm" {
  name                   = "t8p2-tm-profile"
  resource_group_name    = azurerm_resource_group.RG.name
  
  traffic_routing_method = "Priority"

  dns_config {
    relative_name = "t8p2-tm-profile"
    ttl           = 100
  }

  monitor_config {
    protocol                     = "http"
    port                         = 80
    path                         = "/"
    interval_in_seconds          = 30
    timeout_in_seconds           = 9
    tolerated_number_of_failures = 3
  }

}
# change to pip of app services
resource "azurerm_traffic_manager_azure_endpoint" "ep1-external-endpoint" {
  name               = "lb1-external-endpoint"
  profile_id         = azurerm_traffic_manager_profile.t8p2-tm.id
  target_resource_id = azurerm_public_ip.V1toWebPIP.id
  weight             = 100
  priority            = 1
}

/*
#fix me for 2nd vnet
resource "azurerm_traffic_manager_azure_endpoint" "ep2" {
  name               = "lb2-endpoint"
  profile_name         = azurerm_traffic_manager_profile.t8p2-tm.name
  target_resource_id = azurerm_public_ip.V1toWebPIP.id
  weight             = 100
  priority            = 2
}
*/

#------------------------------------------------
#Bastion host
#------------------------------------------------

resource "azurerm_public_ip" "BastionPIP" {
  name                = "BPIP"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "BastionHost" {
  name                = "B1Host"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = module.Network.V1Bastionsubnet1.id
    public_ip_address_id = azurerm_public_ip.BastionPIP.id
  }
}

#------------------------------------------------
#Virtual Machine Scale Sets
#------------------------------------------------



# VMSS Web needs to be changed to web apps services




# VMSS Business
resource "azurerm_virtual_machine_scale_set" "V1VMSSbusiness" {
  name                = var.Vnet1businessVM
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
  upgrade_policy_mode = "Manual"

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



  os_profile {
    computer_name_prefix = var.VMbusinessComputername
    admin_username       = "azureuser"
    admin_password = "Adminpassword*"
  }


  network_profile {
    name    = "terraformnetworkprofile1"
    primary = true

    ip_configuration {
      name                                   = "V1BusinessIPConfiguration"
      primary                                = true
      subnet_id                              = module.Network.v1subnetbusiness
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.V1bpepool2.id]
      load_balancer_inbound_nat_rules_ids    = []
    }
  }

  tags = {
    environment = "JDMB"
  }
}



#We want to make our Load Balancer Public to go to our Web Tier VMSS

resource "azurerm_public_ip" "V1toWebPIP" {
  name                = "PublicIPForLB1"
  location            = "east US"
  resource_group_name = azurerm_resource_group.RG.name
  allocation_method   = "Static"
  domain_name_label   = "lb1-public-ip"
}

resource "azurerm_lb" "V1toWebLB" {
  name                = "V1WLB"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress1"
    public_ip_address_id = azurerm_public_ip.V1toWebPIP.id
    
  }
}

resource "azurerm_lb_backend_address_pool" "V1Pbpepool1" {
  resource_group_name = azurerm_resource_group.RG.name
  loadbalancer_id     = azurerm_lb.V1toWebLB.id
  name                = "V1PBackEndAddressPool1"
}

resource "azurerm_lb_rule" "V1lbrule1" {
  resource_group_name            = azurerm_resource_group.RG.name
  loadbalancer_id                = azurerm_lb.V1toWebLB.id
  name                           = "ssh"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = "PublicIPAddress1"
}

resource "azurerm_lb_rule" "V1lbrule2" {
  resource_group_name            = azurerm_resource_group.RG.name
  loadbalancer_id                = azurerm_lb.V1toWebLB.id
  name                           = "sql"
  protocol                       = "Tcp"
  frontend_port                  = 1433
  backend_port                   = 1433
  frontend_ip_configuration_name = "PublicIPAddress1"
}

resource "azurerm_lb_rule" "V1lbrule3" {
  resource_group_name            = azurerm_resource_group.RG.name
  loadbalancer_id                = azurerm_lb.V1toWebLB.id
  name                           = "web"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress1"
}


resource "azurerm_lb_probe" "V1PHealthProbe1" {
  resource_group_name = azurerm_resource_group.RG.name
  loadbalancer_id     = azurerm_lb.V1toWebLB.id
  name                = "http-probe"
  protocol            = "Http"
  request_path        = "/health"
  port                = 80
}



#We want to make our Load Balancer Internal (Private) to go to our Busines Tier VMSS
resource "azurerm_lb" "V1WebtoBusinessLB" {
  name                = "V1WbLB"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name

  frontend_ip_configuration {
    name                 = "PrivateIPAddress1"
    subnet_id = module.Network.v1subnetbusiness.id
    private_ip_address = "10.0.3.6"
    private_ip_address_allocation = "static"
    private_ip_address_version = "IPv4"
  }
}

resource "azurerm_lb_backend_address_pool" "V1bpepool2" {
  resource_group_name = azurerm_resource_group.RG.name
  loadbalancer_id     = azurerm_lb.V1WebtoBusinessLB.id
  name                = "V1BackEndAddressPool2"
}

resource "azurerm_lb_rule" "V1webtobuslbrule1" {
  resource_group_name            = azurerm_resource_group.RG.name
  loadbalancer_id                = azurerm_lb.V1WebtoBusinessLB.id
  name                           = "ssh"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = "PrivateIPAddress1"
}
resource "azurerm_lb_rule" "V1webtobuslbrule2" {
  resource_group_name            = azurerm_resource_group.RG.name
  loadbalancer_id                = azurerm_lb.V1WebtoBusinessLB.id
  name                           = "sql"
  protocol                       = "Tcp"
  frontend_port                  = 1433
  backend_port                   = 1433
  frontend_ip_configuration_name = "PrivateIPAddress1"
}
resource "azurerm_lb_rule" "V1webtobuslbrule3" {
  resource_group_name            = azurerm_resource_group.RG.name
  loadbalancer_id                = azurerm_lb.V1WebtoBusinessLB.id
  name                           = "web"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PrivateIPAddress1"
}

resource "azurerm_lb_probe" "V1HealthProbe2" {
  resource_group_name = azurerm_resource_group.RG.name
  loadbalancer_id     = azurerm_lb.V1WebtoBusinessLB.id
  name                = "http-probe"
  protocol            = "Http"
  request_path        = "/health"
  port                = 80
}


#We want to make our Load Balancer Internal (Private) to go to our SQL database
resource "azurerm_lb" "V1BusinesstoSQLLB2" {
  name                = "V1BSQlLB2"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name

  frontend_ip_configuration {
    name                 = "PrivateIPAddress2"
    subnet_id = module.Network.v1subnetsql.id
    private_ip_address = "10.0.4.6"
    private_ip_address_allocation = "static"
    private_ip_address_version = "IPv4"
  }
}

resource "azurerm_lb_backend_address_pool" "V1bpepool3" {
  resource_group_name = azurerm_resource_group.RG.name
  loadbalancer_id     = azurerm_lb.V1BusinesstoSQLLB2.id
  name                = "V1BackEndAddressPool3"
}

resource "azurerm_lb_rule" "V1bustosqllbrule1" {
  resource_group_name            = azurerm_resource_group.RG.name
  loadbalancer_id                = azurerm_lb.V1BusinesstoSQLLB2.id
  name                           = "sql"
  protocol                       = "Tcp"
  frontend_port                  = 1433
  backend_port                   = 1433
  frontend_ip_configuration_name = "PrivateIPAddress2"
}

resource "azurerm_lb_probe" "V1HealthProbe3" {
  resource_group_name = azurerm_resource_group.RG.name
  loadbalancer_id     = azurerm_lb.V1BusinesstoSQLLB2.id
  name                = "http-probe"
  protocol            = "Http"
  request_path        = "/health"
  port                = 80
}










#--------------------------------------------
# 2nd Virtual Network
#--------------------------------------------
/*
# look at modules
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
*/

#------------------------------------------------
#Bastion Subnet
#------------------------------------------------

resource "azurerm_public_ip" "BastionPIP2" {
  name                = "BPIP2"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "BastionHost2" {
  name                = "B2Host"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = module.Network.V2Bastionsubnet1.id
    public_ip_address_id = azurerm_public_ip.BastionPIP2.id
  }
}

#------------------------------------------------
#Virtual Machine Scale Sets
#------------------------------------------------



# VMSS Web change to app services




# VMSS Business
resource "azurerm_virtual_machine_scale_set" "V2VMSSbusiness" {
  name                = var.Vnet2businessVM
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
  upgrade_policy_mode = "Manual"

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



  os_profile {
    computer_name_prefix = var.VM2businessComputername
    admin_username       = "azureuser"
    admin_password = "Adminpassword*"
  }


  network_profile {
    name    = "terraformnetworkprofile1"
    primary = true

    ip_configuration {
      name                                   = "V2BusinessIPConfiguration"
      primary                                = true
      subnet_id                              = module.Network.v2subnetbusiness.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.V2bpepool2.id]
      load_balancer_inbound_nat_rules_ids    = []
    }
  }

  tags = {
    environment = "JDMB"
  }
}



#We want to make our Load Balancer Public to go to our Web Tier VMSS

resource "azurerm_public_ip" "V2toWebPIP" {
  name                = "PublicIPForLB2"
  location            = "east US"
  resource_group_name = azurerm_resource_group.RG.name
  allocation_method   = "Static"
  domain_name_label   = "lb2-public-ip"
}

resource "azurerm_lb" "V2toWebLB" {
  name                = "V2WLB"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress2"
    public_ip_address_id = azurerm_public_ip.V2toWebPIP.id
    
  }
}

resource "azurerm_lb_backend_address_pool" "V2Pbpepool1" {
  resource_group_name = azurerm_resource_group.RG.name
  loadbalancer_id     = azurerm_lb.V2toWebLB.id
  name                = "V2PBackEndAddressPool1"
}

resource "azurerm_lb_rule" "V2lbrule1" {
  resource_group_name            = azurerm_resource_group.RG.name
  loadbalancer_id                = azurerm_lb.V2toWebLB.id
  name                           = "ssh"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = "PublicIPAddress2"
}

resource "azurerm_lb_rule" "V2lbrule2" {
  resource_group_name            = azurerm_resource_group.RG.name
  loadbalancer_id                = azurerm_lb.V2toWebLB.id
  name                           = "sql"
  protocol                       = "Tcp"
  frontend_port                  = 1433
  backend_port                   = 1433
  frontend_ip_configuration_name = "PublicIPAddress2"
}

resource "azurerm_lb_rule" "V2lbrule3" {
  resource_group_name            = azurerm_resource_group.RG.name
  loadbalancer_id                = azurerm_lb.V2toWebLB.id
  name                           = "web"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress2"
}


resource "azurerm_lb_probe" "V2PHealthProbe1" {
  resource_group_name = azurerm_resource_group.RG.name
  loadbalancer_id     = azurerm_lb.V2toWebLB.id
  name                = "http-probe"
  protocol            = "Http"
  request_path        = "/health"
  port                = 80
}



#We want to make our Load Balancer Internal (Private) to go to our Busines Tier VMSS
resource "azurerm_lb" "V2WebtoBusinessLB" {
  name                = "V2WbLB"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name

  frontend_ip_configuration {
    name                 = "PrivateIPAddress2"
    subnet_id = module.Network.v2subnetbusiness.id
    private_ip_address = "10.1.3.6"
    private_ip_address_allocation = "static"
    private_ip_address_version = "IPv4"
  }
}

resource "azurerm_lb_backend_address_pool" "V2bpepool2" {
  resource_group_name = azurerm_resource_group.RG.name
  loadbalancer_id     = azurerm_lb.V2WebtoBusinessLB.id
  name                = "V2BackEndAddressPool2"
}

resource "azurerm_lb_rule" "V2webtobuslbrule1" {
  resource_group_name            = azurerm_resource_group.RG.name
  loadbalancer_id                = azurerm_lb.V2WebtoBusinessLB.id
  name                           = "ssh"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = "PrivateIPAddress2"
}
resource "azurerm_lb_rule" "V2webtobuslbrule2" {
  resource_group_name            = azurerm_resource_group.RG.name
  loadbalancer_id                = azurerm_lb.V2WebtoBusinessLB.id
  name                           = "sql"
  protocol                       = "Tcp"
  frontend_port                  = 1433
  backend_port                   = 1433
  frontend_ip_configuration_name = "PrivateIPAddress2"
}
resource "azurerm_lb_rule" "V2webtobuslbrule3" {
  resource_group_name            = azurerm_resource_group.RG.name
  loadbalancer_id                = azurerm_lb.V2WebtoBusinessLB.id
  name                           = "web"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PrivateIPAddress2"
}

resource "azurerm_lb_probe" "V2HealthProbe2" {
  resource_group_name = azurerm_resource_group.RG.name
  loadbalancer_id     = azurerm_lb.V2WebtoBusinessLB.id
  name                = "http-probe"
  protocol            = "Http"
  request_path        = "/health"
  port                = 80
}


#We want to make our Load Balancer Internal (Private) to go to our SQL database
resource "azurerm_lb" "V2BusinesstoSQLLB2" {
  name                = "V2BSQlLB2"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name

  frontend_ip_configuration {
    name                 = "PrivateIPAddress2"
    subnet_id = module.Network.v2subnetsql.id
    private_ip_address = "10.1.4.6"
    private_ip_address_allocation = "static"
    private_ip_address_version = "IPv4"
  }
}

resource "azurerm_lb_backend_address_pool" "V2bpepool3" {
  resource_group_name = azurerm_resource_group.RG.name
  loadbalancer_id     = azurerm_lb.V2BusinesstoSQLLB2.id
  name                = "V2BackEndAddressPool3"
}

resource "azurerm_lb_rule" "V2bustosqllbrule1" {
  resource_group_name            = azurerm_resource_group.RG.name
  loadbalancer_id                = azurerm_lb.V2BusinesstoSQLLB2.id
  name                           = "sql"
  protocol                       = "Tcp"
  frontend_port                  = 1433
  backend_port                   = 1433
  frontend_ip_configuration_name = "PrivateIPAddress2"
}

resource "azurerm_lb_probe" "V2HealthProbe3" {
  resource_group_name = azurerm_resource_group.RG.name
  loadbalancer_id     = azurerm_lb.V2BusinesstoSQLLB2.id
  name                = "http-probe"
  protocol            = "Http"
  request_path        = "/health"
  port                = 80
}