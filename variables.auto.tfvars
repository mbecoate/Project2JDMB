

tags = {
  Name = "JDMB",
  Team = "Team8"
}


#resource group variables
rg_name  = "Team8_Project2_1"
location1 = "eastus"
location2 = "centralus"


#Vault Variables
secrets_rg_name   = "secrets"
secret_vault_name = "mattbkeyvaultTF"


/*
#Networking Variables
network_NSG     = "Network_security_Group"
*/
/*
Vnet1WebVM = "V1WebVMSS"
VMwebComputername = "V1webComputer"
Vnet2WebVM = "V2WebVMSS"
VM2webComputername = "V2webComputer"
*/


#VMSS 
Vnet1businessVM = "V1businessVMSS"
VMbusinessComputername = "V1businesscomputer"
Vnet2businessVM = "V2businessVMSS"
VM2businessComputername = "V2businesscomputer"


#VM Variables

#PIP
linux1_pip_allocation_method = "Dynamic"

#linux1_VM
linux1_publisher                = "Canonical"
linux1_offer                    = "UbuntuServer"
linux1_sku                      = "18.04-LTS"
linux1_version                  = "latest"
linux1_storage_os_disk_caching  = "ReadWrite"
linux1_create_option            = "FromImage"
linux1_managed_disk_type        = "Standard_LRS"
linux1_os_profile_computer_name = "hostname"

#Security Variables
security_rule_name                       = "allow-22"
security_rule_priority                   = 100
security_rule_direction                  = "Inbound"
security_rule_access                     = "Allow"
security_rule_protocol                   = "Tcp"
security_rule_source_port_range          = "*"
security_rule_destination_port_range     = "*"
security_rule_source_address_prefix      = "*"
security_rule_destination_address_prefix = "*"


