

variable "tags" {
  type = map(string)
}


#resource group variables
variable "rg_name" {
  type = string
}
variable "location" {
  type = string
}


variable "secret_vault_name" {
  type = string
}
variable "secrets_rg_name" {
  type = string
}


/*
#Networking Variables
variable "network_NSG" {
  type = string
}
*/


/*
#sql vm ?
variable "Vnet1WebVM" {
  type = string
}
variable "VMwebComputername" {
  type = string
}
variable "Vnet2WebVM" {
  type = string
}
variable "VM2webComputername" {
  type = string
}
*/

#VMSS Variables
variable "Vnet1businessVM" {
  type = string
}
variable "VMbusinessComputername" {
  type = string
}
variable "Vnet2businessVM" {
  type = string
}
variable "VM2businessComputername" {
  type = string
}





variable "security_rule_name" {
  type = string
}
variable "security_rule_direction" {
  type = string
}
variable "security_rule_priority" {
  type = number
}
variable "security_rule_access" {
  type = string
}
variable "security_rule_protocol" {
  type = string
}
variable "security_rule_source_port_range" {
  type = string
}
variable "security_rule_destination_port_range" {
  type = string
}
variable "security_rule_source_address_prefix" {
  type = string
}
variable "security_rule_destination_address_prefix" {
  type = string
}




