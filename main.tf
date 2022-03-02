resource "azurerm_resource_group" "RG" {
  name     = var.rg_name
  location = var.location1
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

  depends_on = [
    azurerm_resource_group.RG
  ]
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
resource "azurerm_traffic_manager_azure_endpoint" "ep1-external-endpoint" {
  name               = "lb1-external-endpoint"
  profile_id         = azurerm_traffic_manager_profile.t8p2-tm.id
  target_resource_id = azurerm_public_ip.vappgatewaypip1.id
  weight             = 100
  priority            = 1
}
resource "azurerm_traffic_manager_azure_endpoint" "ep2-external-endpoint" {
  name               = "lb2-external-endpoint"
  profile_id         = azurerm_traffic_manager_profile.t8p2-tm.id
  target_resource_id = azurerm_public_ip.vappgatewaypip2.id
  weight             = 101
  priority            = 2
}


#------------------------------------------------
#Bastion host
#------------------------------------------------

resource "azurerm_public_ip" "BastionPIP" {
  name                = "BPIP"
  location            = var.location1
  resource_group_name = azurerm_resource_group.RG.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "BastionHost" {
  name                = "B1Host"
  location            = var.location1
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
  location            = var.location1
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
      subnet_id                              = module.Network.v1subnetbusiness.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.V1bpepool2.id]
      load_balancer_inbound_nat_rules_ids    = []
    }
  }
}




#We want to make our Load Balancer Internal (Private) to go to our Busines Tier VMSS
resource "azurerm_lb" "V1WebtoBusinessLB" {
  name                = "V1WbLB"
  location            = var.location1
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
  //protocol            = "Http"
  //request_path        = "/health"
  port                = 80
}

/*
#We want to make our Load Balancer Internal (Private) to go to our SQL database
resource "azurerm_lb" "V1BusinesstoSQLLB2" {
  name                = "V1BSQlLB2"
  location            = var.location1
  resource_group_name = azurerm_resource_group.RG.name
  sku = "Standard"

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

resource "azurerm_lb_backend_address_pool_address" "address1" {
  name                    = "address1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.V1bpepool3.id
  virtual_network_id      = module.Network.Vnet1.id
  ip_address              = "10.0.4.7"
}

resource "azurerm_lb_backend_address_pool_address" "address2" {
  name                    = "address2"
  backend_address_pool_id = azurerm_lb_backend_address_pool.V1bpepool3.id
  virtual_network_id      = module.Network.Vnet1.id
  ip_address              = "10.0.4.8"
}

resource "azurerm_lb_rule" "V1bustosqllbrule1" {
  resource_group_name            = azurerm_resource_group.RG.name
  loadbalancer_id                = azurerm_lb.V1BusinesstoSQLLB2.id
  name                           = "sql"
  protocol                       = "Tcp"
  frontend_port                  = 1433
  backend_port                   = 1433
  frontend_ip_configuration_name = "PrivateIPAddress2"
  backend_address_pool_id = azurerm_lb_backend_address_pool.V1bpepool3.id
  probe_id = azurerm_lb_probe.V1HealthProbe3.id
}
resource "azurerm_lb_rule" "V1bustosqllbrule2" {
  resource_group_name            = azurerm_resource_group.RG.name
  loadbalancer_id                = azurerm_lb.V1BusinesstoSQLLB2.id
  name                           = "ssh"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = "PrivateIPAddress2"
  backend_address_pool_id = azurerm_lb_backend_address_pool.V1bpepool3.id
  probe_id = azurerm_lb_probe.V1HealthProbe3.id
}
resource "azurerm_lb_rule" "V1bustosqllbrule3" {
  resource_group_name            = azurerm_resource_group.RG.name
  loadbalancer_id                = azurerm_lb.V1BusinesstoSQLLB2.id
  name                           = "web"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PrivateIPAddress2"
  backend_address_pool_id = azurerm_lb_backend_address_pool.V1bpepool3.id
  probe_id = azurerm_lb_probe.V1HealthProbe3.id
}
resource "azurerm_lb_probe" "V1HealthProbe3" {
  resource_group_name = azurerm_resource_group.RG.name
  loadbalancer_id     = azurerm_lb.V1BusinesstoSQLLB2.id
  name                = "http-probe"
  //protocol            = "Http"
  //request_path        = "/health"
  port                = 80
}
*/




#--------------------------------------------
# 2nd Virtual Network
#--------------------------------------------


#------------------------------------------------
#Bastion Subnet
#------------------------------------------------

resource "azurerm_public_ip" "BastionPIP2" {
  name                = "BPIP2"
  location            = var.location2
  resource_group_name = azurerm_resource_group.RG.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "BastionHost2" {
  name                = "B2Host"
  location            = var.location2
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
  location            = var.location2
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
}


#We want to make our Load Balancer Internal (Private) to go to our Busines Tier VMSS
resource "azurerm_lb" "V2WebtoBusinessLB" {
  name                = "V2WbLB"
  location            = var.location2
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
  //protocol            = "Http"
  //request_path        = "/health"
  port                = 80
}

/*
#We want to make our Load Balancer Internal (Private) to go to our SQL database
resource "azurerm_lb" "V2BusinesstoSQLLB2" {
  name                = "V2BSQlLB2"
  location            = var.location2
  resource_group_name = azurerm_resource_group.RG.name
  sku = "Standard"

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

resource "azurerm_lb_backend_address_pool_address" "address3" {
  name                    = "address3"
  backend_address_pool_id = azurerm_lb_backend_address_pool.V2bpepool3.id
  virtual_network_id      = module.Network.Vnet2.id
  ip_address              = "10.1.4.7"
}

resource "azurerm_lb_backend_address_pool_address" "address4" {
  name                    = "address4"
  backend_address_pool_id = azurerm_lb_backend_address_pool.V2bpepool3.id
  virtual_network_id      = module.Network.Vnet2.id
  ip_address              = "10.1.4.8"
}

resource "azurerm_lb_rule" "V2bustosqllbrule1" {
  resource_group_name            = azurerm_resource_group.RG.name
  loadbalancer_id                = azurerm_lb.V2BusinesstoSQLLB2.id
  name                           = "sql"
  protocol                       = "Tcp"
  frontend_port                  = 1433
  backend_port                   = 1433
  frontend_ip_configuration_name = "PrivateIPAddress2"
  backend_address_pool_id = azurerm_lb_backend_address_pool.V2bpepool3.id
  probe_id = azurerm_lb_probe.V2HealthProbe3.id
}
resource "azurerm_lb_rule" "V2bustosqllbrule2" {
  resource_group_name            = azurerm_resource_group.RG.name
  loadbalancer_id                = azurerm_lb.V2BusinesstoSQLLB2.id
  name                           = "ssh"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = "PrivateIPAddress2"
  backend_address_pool_id = azurerm_lb_backend_address_pool.V2bpepool3.id
  probe_id = azurerm_lb_probe.V2HealthProbe3.id
}
resource "azurerm_lb_rule" "V2bustosqllbrule3" {
  resource_group_name            = azurerm_resource_group.RG.name
  loadbalancer_id                = azurerm_lb.V2BusinesstoSQLLB2.id
  name                           = "web"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PrivateIPAddress2"
  backend_address_pool_id = azurerm_lb_backend_address_pool.V2bpepool3.id
  probe_id = azurerm_lb_probe.V2HealthProbe3.id
}
resource "azurerm_lb_probe" "V2HealthProbe3" {
  resource_group_name = azurerm_resource_group.RG.name
  loadbalancer_id     = azurerm_lb.V2BusinesstoSQLLB2.id
  name                = "http-probe"
  //protocol            = "Http"
  //request_path        = "/health"
  port                = 80
}
*/







#----------------------------
#App Service 1
#----------------------------

resource "azurerm_app_service_plan" "appserviceplan1" {
  name                = "appservice1"
  location            = var.location1
  resource_group_name = azurerm_resource_group.RG.name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Standard"
    size = "S1"
    capacity = "3"
  }
}

resource "azurerm_app_service" "appservice1" {
  name                = "app-service1"
  location            = var.location1
  resource_group_name = azurerm_resource_group.RG.name
  app_service_plan_id = azurerm_app_service_plan.appserviceplan1.id

  site_config {
    app_command_line = ""
    linux_fx_version = "DOCKER|mbecoate/movie_app:latest"
    health_check_path = "/health"
  }

  app_settings = {
    "SOME_KEY" = "some-value"

    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "DOCKER_REGISTRY_SERVER_URL"          = "https://index.docker.io"
  
  }
/*
  connection_string {
    name  = "Database"
    type  = "SQLServer"
    value = "Server=some-server.mydomain.com;Integrated Security=SSPI"
  }
  */
}




#----------------------------
#App Service 2
#----------------------------

resource "azurerm_app_service_plan" "appserviceplan2" {
  name                = "appservice2"
  location            = var.location2
  resource_group_name = azurerm_resource_group.RG.name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Standard"
    size = "S1"
    capacity = "3"
  }
}

resource "azurerm_app_service" "appservice2" {
  name                = "app-service2"
  location            = var.location2
  resource_group_name = azurerm_resource_group.RG.name
  app_service_plan_id = azurerm_app_service_plan.appserviceplan2.id

  site_config {
    app_command_line = ""
    linux_fx_version = "DOCKER|mbecoate/movie_app:latest"
    health_check_path = "/health"
  }

  app_settings = {
    "SOME_KEY" = "some-value"
    
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "DOCKER_REGISTRY_SERVER_URL"          = "https://index.docker.io"
    
  }
/*
  connection_string {
    name  = "Database"
    type  = "SQLServer"
    value = "Server=some-server.mydomain.com;Integrated Security=SSPI"
  }
  */

}



#------------------------------
#Virtual Application Gateway in Vnet 1
#------------------------------



resource "azurerm_public_ip" "vappgatewaypip1" {
  name                = "vappgateway1-pip"
  resource_group_name = azurerm_resource_group.RG.name
  location            = var.location1
  allocation_method   = "Dynamic"
  domain_name_label = "vappgateway1"
}

#&nbsp;since these variables are re-used - a locals block makes this more maintainable
locals {
  backend_address_pool_name      = "${module.Network.Vnet1.name}-beap"
  frontend_port_name             = "${module.Network.Vnet1.name}-feport"
  frontend_ip_configuration_name = "${module.Network.Vnet1.name}-feip"
  http_setting_name              = "${module.Network.Vnet1.name}-be-htst"
  listener_name                  = "${module.Network.Vnet1.name}-httplstn"
  request_routing_rule_name      = "${module.Network.Vnet1.name}-rqrt"
  redirect_configuration_name    = "${module.Network.Vnet1.name}-rdrcfg"
}

resource "azurerm_application_gateway" "vappgateway1" {
  name                = "v-appgateway1"
  resource_group_name = azurerm_resource_group.RG.name
  location            = var.location1

  sku {
    name     = "Standard_Small"
    tier     = "Standard"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = module.Network.v1subnetvagfe.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.vappgatewaypip1.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
    fqdns = ["${azurerm_app_service.appservice1.name}.azurewebsites.net"]
  }

  backend_http_settings {
    name                  = local.http_setting_name
    pick_host_name_from_backend_address = true
    probe_name = "p1"
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
    //host_name = "${azurerm_app_service.appservice2.name}.azurewebsites.net"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }

  probe {
    name = "p1"
    interval = 30
    protocol = "Http"
    path = "/"
    timeout = 60
    unhealthy_threshold = 3
    pick_host_name_from_backend_http_settings = true
    match {
      status_code = [200, 399, 404]
    }
  }
}




#------------------------------
#Virtual Application Gateway in Vnet2 
#------------------------------



resource "azurerm_public_ip" "vappgatewaypip2" {
  name                = "vappgateway2-pip"
  resource_group_name = azurerm_resource_group.RG.name
  location            = var.location2
  allocation_method   = "Dynamic"
  domain_name_label = "vappgateway2"
}

#&nbsp;since these variables are re-used - a locals block makes this more maintainable
locals {
  backend_address_pool_name2      = "${module.Network.Vnet2.name}-beap"
  frontend_port_name2             = "${module.Network.Vnet2.name}-feport"
  frontend_ip_configuration_name2 = "${module.Network.Vnet2.name}-feip"
  http_setting_name2              = "${module.Network.Vnet2.name}-be-htst"
  listener_name2                  = "${module.Network.Vnet2.name}-httplstn"
  request_routing_rule_name2      = "${module.Network.Vnet2.name}-rqrt"
  redirect_configuration_name2    = "${module.Network.Vnet2.name}-rdrcfg"
}

resource "azurerm_application_gateway" "vappgateway2" {
  name                = "v-appgateway2"
  resource_group_name = azurerm_resource_group.RG.name
  location            = var.location2

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
    name = local.frontend_port_name2
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name2
    public_ip_address_id = azurerm_public_ip.vappgatewaypip2.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name2
    fqdns = ["${azurerm_app_service.appservice2.name}.azurewebsites.net"]
  }

  backend_http_settings {
    name                  = local.http_setting_name2
    pick_host_name_from_backend_address = true
    probe_name = "p2"
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name2
    frontend_ip_configuration_name = local.frontend_ip_configuration_name2
    frontend_port_name             = local.frontend_port_name2
    protocol                       = "Http"
    //host_name = "${azurerm_app_service.appservice2.name}.azurewebsites.net"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name2
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name2
    backend_address_pool_name  = local.backend_address_pool_name2
    backend_http_settings_name = local.http_setting_name2
  }

  probe {
    name = "p2"
    interval = 30
    protocol = "Http"
    path = "/"
    timeout = 60
    unhealthy_threshold = 3
    pick_host_name_from_backend_http_settings = true
    match {
      status_code = [200, 399, 404]
    }
  }

}






#New SQL SERVER
resource "azurerm_sql_server" "primary_sql_server" {
  name                         = "vnet1-sql-primary"
  resource_group_name          = azurerm_resource_group.RG.name
  location                     = var.location1
  version                      = "12.0"
  administrator_login          = "azureuser"
  administrator_login_password = "Adminpassword*"
}

resource "azurerm_sql_server" "secondary" {
  name                         = "vnet2-sql-secondary"
  resource_group_name          = azurerm_resource_group.RG.name
  location                     = var.location2
  version                      = "12.0"
  administrator_login          = "azureuser"
  administrator_login_password = "Adminpassword*"
}

resource "azurerm_sql_database" "db1" {
  name                = "t8p2-db1"
  resource_group_name = azurerm_resource_group.RG.name
  location            = var.location1
  server_name         = azurerm_sql_server.primary_sql_server.name
}

resource "azurerm_sql_failover_group" "fallover_group" {
  name                = "t8p2-failover-group"
  resource_group_name = azurerm_sql_server.primary_sql_server.resource_group_name
  server_name         = azurerm_sql_server.primary_sql_server.name
  databases           = [azurerm_sql_database.db1.id]
  partner_servers {
    id = azurerm_sql_server.secondary.id
  }

  read_write_endpoint_failover_policy {
    mode          = "Automatic"
    grace_minutes = 60
  }
}


#------------------------------
#Virtual Application Gateway for sql1 in Vnet1 
#------------------------------



#&nbsp;since these variables are re-used - a locals block makes this more maintainable
locals {
  backend_address_pool_name3      = "${module.Network.Vnet1.name}-beap2"
  frontend_port_name3             = "${module.Network.Vnet1.name}-feport2"
  frontend_ip_configuration_name3 = "${module.Network.Vnet1.name}-feip2"
  http_setting_name3              = "${module.Network.Vnet1.name}-be-htst2"
  listener_name3                  = "${module.Network.Vnet1.name}-httplstn2"
  request_routing_rule_name3      = "${module.Network.Vnet1.name}-rqrt2"
  redirect_configuration_name3    = "${module.Network.Vnet1.name}-rdrcfg2"
}

resource "azurerm_application_gateway" "vappgateway3" {
  name                = "v-appgateway3"
  resource_group_name = azurerm_resource_group.RG.name
  location            = var.location1

  sku {
    name     = "Standard_Small"
    tier     = "Standard"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = module.Network.v1subnetvagbe.id
  }

  frontend_port {
    name = local.frontend_port_name3
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name3
    subnet_id = module.Network.v2subnetvagbe.id
    private_ip_address_allocation = "Static"
    private_ip_address = "10.0.6.6"
  }

  backend_address_pool {
    name = local.backend_address_pool_name2
    fqdns = ["${azurerm_sql_server.primary_sql_server.name}.database.windows.net"]
  }

  backend_http_settings {
    name                  = local.http_setting_name3
    pick_host_name_from_backend_address = true
    probe_name = "p3"
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name3
    frontend_ip_configuration_name = local.frontend_ip_configuration_name3
    frontend_port_name             = local.frontend_port_name3
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name3
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name3
    backend_address_pool_name  = local.backend_address_pool_name3
    backend_http_settings_name = local.http_setting_name3
  }

  probe {
    name = "p3"
    interval = 30
    protocol = "Http"
    path = "/"
    timeout = 60
    unhealthy_threshold = 3
    pick_host_name_from_backend_http_settings = true
    match {
      status_code = [200, 399, 404]
    }
  }

}


#------------------------------
#Virtual Application Gateway for sql2 in Vnet2 
#------------------------------




#&nbsp;since these variables are re-used - a locals block makes this more maintainable
locals {
  backend_address_pool_name4      = "${module.Network.Vnet2.name}-beap2"
  frontend_port_name4             = "${module.Network.Vnet2.name}-feport2"
  frontend_ip_configuration_name4 = "${module.Network.Vnet2.name}-feip2"
  http_setting_name4              = "${module.Network.Vnet2.name}-be-htst2"
  listener_name4                 = "${module.Network.Vnet2.name}-httplstn2"
  request_routing_rule_name4      = "${module.Network.Vnet2.name}-rqrt2"
  redirect_configuration_name4   = "${module.Network.Vnet2.name}-rdrcfg2"
}

resource "azurerm_application_gateway" "vappgateway4" {
  name                = "v-appgateway4"
  resource_group_name = azurerm_resource_group.RG.name
  location            = var.location2

  sku {
    name     = "Standard_Small"
    tier     = "Standard"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = module.Network.v2subnetvagbe.id
  }

  frontend_port {
    name = local.frontend_port_name4
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name4
    subnet_id = module.Network.v2subnetvagbe.id
    private_ip_address_allocation = "Static"
    private_ip_address = "10.1.6.6"
  }

  backend_address_pool {
    name = local.backend_address_pool_name4
    fqdns = ["${azurerm_sql_server.secondary.name}.database.windows.net"]
  }

  backend_http_settings {
    name                  = local.http_setting_name4
    pick_host_name_from_backend_address = true
    probe_name = "p4"
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name4
    frontend_ip_configuration_name = local.frontend_ip_configuration_name4
    frontend_port_name             = local.frontend_port_name4
    protocol                       = "Http"
    //host_name = "${azurerm_app_service.appservice2.name}.azurewebsites.net"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name4
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name4
    backend_address_pool_name  = local.backend_address_pool_name4
    backend_http_settings_name = local.http_setting_name4
  }

  probe {
    name = "p4"
    interval = 30
    protocol = "Http"
    path = "/"
    timeout = 60
    unhealthy_threshold = 3
    pick_host_name_from_backend_http_settings = true
    match {
      status_code = [200, 399, 404]
    }
  }

}







