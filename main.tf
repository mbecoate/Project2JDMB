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


#traffic manager ENDPOINTS

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
# change to application gatway frontend
resource "azurerm_traffic_manager_azure_endpoint" "ep1-external-endpoint" {
  name               = "lb1-external-endpoint"
  profile_id         = azurerm_traffic_manager_profile.t8p2-tm.id
  target_resource_id = azurerm_public_ip.V1toWebPIP.id
  weight             = 100
  priority            = 1
}
#fix me for 2nd vnet
resource "azurerm_traffic_manager_azure_endpoint" "ep2" {
  name               = "lb2-endpoint"
  profile_name         = azurerm_traffic_manager_profile.t8p2-tm.name
  target_resource_id = azurerm_public_ip.V1toWebPIP.id
  weight             = 100
  priority            = 2
}


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


#change to app services or remove?
#We want to make our Load Balancer Public to go to our Web Tier VMSS
/*
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
*/


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

#removed public load balancer


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




#------------------------------
#SQL Server Always On 1 in VNet1 (add LRS)
#------------------------------

/*resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = Module.Network.VNet1subnetsql.id
  network_security_group_id = azurerm_network_security_group.example.id
}
*/
/*
resource "azurerm_public_ip" "vm" {
  name                = "${var.prefix}-PIP"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
  allocation_method   = "Dynamic"
}
*/

/*
resource "azurerm_network_security_group" "example" {
  name                = "${var.prefix}-NSG"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
}

resource "azurerm_network_security_rule" "RDPRule" {
  name                        = "RDPRule"
  resource_group_name         = azurerm_resource_group.RG.name
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = 3389
  source_address_prefix       = "167.220.255.0/25"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.example.name
}

resource "azurerm_network_security_rule" "MSSQLRule" {
  name                        = "MSSQLRule"
  resource_group_name         = azurerm_resource_group.RG.name
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = 1433
  source_address_prefix       = "167.220.255.0/25"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.example.name
}
*/

resource "azurerm_network_interface" "sqlnic1" {
  name                = "sqlservernic1"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name

  ip_configuration {
    name                          = "sqlipconfiguration1"
    subnet_id                     = module.Network.v1subnetsql.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.4.6"
  }
}

/*
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.example.id
  network_security_group_id = azurerm_network_security_group.example.id
}
*/

resource "azurerm_virtual_machine" "sqlvm1" {
  name                  = "sqlservervm1"
  location              = azurerm_resource_group.RG.location
  resource_group_name   = azurerm_resource_group.RG.name
  network_interface_ids = [azurerm_network_interface.example.id]
  vm_size               = "Standard_DS14_v2"

  storage_image_reference {
    publisher = "MicrosoftSQLServer"
    offer     = "SQL2017-WS2016"
    sku       = "SQLDEV"
    version   = "latest"
  }

  storage_os_disk {
    name              = "sqlstorage1-OSDisk"
    caching           = "ReadOnly"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  os_profile {
    computer_name  = "sqlservervm"
    admin_username = "azureuser"
    admin_password = "Adminpassword*"
  }

  os_profile_windows_config {
    timezone                  = "Eastern Standard Time"
    provision_vm_agent        = true
    enable_automatic_upgrades = true
  }
}


#------------------------------
#SQL Server Always On #2 in Vnet1
#------------------------------

resource "azurerm_network_interface" "sqlnic2" {
  name                = "sqlservernic2"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name

  ip_configuration {
    name                          = "sqlipconfiguration2"
    subnet_id                     = module.Network.v1subnetsql.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.4.7"
  }
}

resource "azurerm_virtual_machine" "sqlvm2" {
  name                  = "sqlservervm2"
  location              = azurerm_resource_group.RG.location
  resource_group_name   = azurerm_resource_group.RG.name
  network_interface_ids = [azurerm_network_interface.example.id]
  vm_size               = "Standard_DS14_v2"

  storage_image_reference {
    publisher = "MicrosoftSQLServer"
    offer     = "SQL2017-WS2016"
    sku       = "SQLDEV"
    version   = "latest"
  }

  storage_os_disk {
    name              = "sqlstorage1-OSDisk"
    caching           = "ReadOnly"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  os_profile {
    computer_name  = "sqlservervm"
    admin_username = "azureuser"
    admin_password = "Adminpassword*"
  }

  os_profile_windows_config {
    timezone                  = "Eastern Standard Time"
    provision_vm_agent        = true
    enable_automatic_upgrades = true
  }
}




#----------------------------
#App Service 1
#----------------------------

resource "azurerm_app_service_plan" "appserviceplan1" {
  name                = "appservice1"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "appservice1" {
  name                = "app_service1"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
  app_service_plan_id = azurerm_app_service_plan.appserviceplan1.id

  site_config {
    dotnet_framework_version = "v4.0"
    scm_type                 = "LocalGit"
  }

  app_settings = {
    "SOME_KEY" = "some-value"
  }

  connection_string {
    name  = "Database"
    type  = "SQLServer"
    value = "Server=some-server.mydomain.com;Integrated Security=SSPI"
  }
}




#----------------------------
#App Service 2
#----------------------------

resource "azurerm_app_service_plan" "appserviceplan2" {
  name                = "appservice2"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "appservice2" {
  name                = "app_service2"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
  app_service_plan_id = azurerm_app_service_plan.appserviceplan2.id

  site_config {
    dotnet_framework_version = "v4.0"
    scm_type                 = "LocalGit"
  }

  app_settings = {
    "SOME_KEY" = "some-value"
  }

  connection_string {
    name  = "Database"
    type  = "SQLServer"
    value = "Server=some-server.mydomain.com;Integrated Security=SSPI"
  }
}



#------------------------------
#Virtual Application Gateway in Vnet 1
#------------------------------



resource "azurerm_public_ip" "example" {
  name                = "example-pip"
  resource_group_name = azurerm_resource_group.RG.name
  location            = azurerm_resource_group.RG.location
  allocation_method   = "Dynamic"
}

#&nbsp;since these variables are re-used - a locals block makes this more maintainable
locals {
  backend_address_pool_name      = "${azurerm_virtual_network.example.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.example.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.example.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.example.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.example.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.example.name}-rqrt"
  redirect_configuration_name    = "${azurerm_virtual_network.example.name}-rdrcfg"
}

resource "azurerm_application_gateway" "network" {
  name                = "example-appgateway"
  resource_group_name = azurerm_resource_group.RG.name
  location            = azurerm_resource_group.RG.location

  sku {
    name     = "Standard_Small"
    tier     = "Standard"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.frontend.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.example.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }
}




#------------------------------
#Virtual Application Gateway in Vnet2 
#------------------------------



resource "azurerm_public_ip" "example" {
  name                = "example-pip"
  resource_group_name = azurerm_resource_group.RG.name
  location            = azurerm_resource_group.RG.location
  allocation_method   = "Dynamic"
}

#&nbsp;since these variables are re-used - a locals block makes this more maintainable
locals {
  backend_address_pool_name      = "${azurerm_virtual_network.example.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.example.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.example.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.example.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.example.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.example.name}-rqrt"
  redirect_configuration_name    = "${azurerm_virtual_network.example.name}-rdrcfg"
}

resource "azurerm_application_gateway" "network" {
  name                = "example-appgateway"
  resource_group_name = azurerm_resource_group.RG.name
  location            = azurerm_resource_group.RG.location

  sku {
    name     = "Standard_Small"
    tier     = "Standard"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = module.Network.v2subnetvagfe.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.example.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }
}