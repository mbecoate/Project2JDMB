#resource group variables
variable "rg_name" {
  type = string
}
variable "location" {
  type = string
}

#Networking Variables
variable "network_NSG" {
  type = string
}
variable "Vnet1network_name" {
  type = string
}
variable "Vnet2network_name" {
  type = string
}
variable "address_space" {
  type = list(string)
}
variable "address_space2" {
  type = list(string)
}
variable "v1subnetweb" {
  type = string
}
variable "v2subnetweb" {
  type = string
}

variable "v1subnetweb_address" {
  type = list(string)
}
variable "v2subnetweb_address" {
  type = list(string)
}

variable "v1subnetbusiness" {
  type = string
}
variable "v2subnetbusiness" {
  type = string
}

variable "v1subnetbusiness_address" {
  type = list(string)
}
variable "v2subnetbusiness_address" {
  type = list(string)
}

variable "v1subnetsql" {
  type = string
}
variable "v2subnetsql" {
  type = string
}

variable "v1subnetsql_address" {
  type = list(string)
}
variable "v2subnetsql_address" {
  type = list(string)
}

variable "V1Bastionsubnet" {
  type = string
}
variable "V1Bastionsubnet1_address" {
  type = list(string)
}

variable "V2Bastionsubnet" {
  type = string
}
variable "V2Bastionsubnet1_address" {
  type = list(string)
}


#VMSS Variables

variable "Vnet1WebVM" {
  type = string
}
variable "VMwebComputername" {
  type = string
}

variable "Vnet1businessVM" {
  type = string
}
variable "VMbusinessComputername" {
  type = string
}

variable "Vnet2WebVM" {
  type = string
}
variable "VM2webComputername" {
  type = string
}

variable "Vnet2businessVM" {
  type = string
}
variable "VM2businessComputername" {
  type = string
}




variable "tags" {
  type = map(string)
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

variable "secret_vault_name" {
  type = string
}
variable "secrets_rg_name" {
  type = string
}


