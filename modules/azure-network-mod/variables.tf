
#tags
variable "tags" {
    description = "Tags to use."
    type = map(string)
    default = {}
}


#resource group
variable "rg" {
    description = "Resource Group to add to."
    type  = string
}


#Networking Variables
variable "vnet1location" {
    description = "location for first network"
    type = string
    default = "eastus"
}
variable "vnet2location" {
    description = "location for seconed network"
    type = string
    default = "centralus"
}


variable "V1Bastionsubnet" {
  type = string
  default = "V1Bastionsubnet"
}
variable "V1Bastionsubnet1_address" {
  type = list(string)
  default = [ "10.0.1.0/16" ]
}
variable "V2Bastionsubnet" {
  type = string
  default = "V2Bastionsubnet"
}
variable "V2Bastionsubnet1_address" {
  type = list(string)
  default = [ "10.1.1.0/16" ]
}


variable "Vnet1network_name" {
  type = string
  default = "Vnet1network_name"
}
variable "Vnet2network_name" {
  type = string
  default = "Vnet2network_name"
}
variable "address_space" {
  type = list(string)
  default = ["10.0.0.0/16"]
}
variable "address_space2" {
  type = list(string)
  default = ["10.1.0.0/16"]
}


variable "v1subnetbusiness" {
  type = string
  default = "v1subnetbusiness"
}
variable "v2subnetbusiness" {
  type = string
  default = "v2subnetbusiness"
}
variable "v1subnetbusiness_address" {
  type = list(string)
  default = [ "10.0.3.0/16" ]
}
variable "v2subnetbusiness_address" {
  type = list(string)
  default = [ "10.1.3.0/16" ]
}


variable "v1subnetsql" {
  type = string
  default = "v1subnetsql"
}
variable "v2subnetsql" {
  type = string
  default = "v2subnetsql"
}
variable "v1subnetsql_address" {
  type = list(string)
  default = [ "10.0.4.0/16" ]
}
variable "v2subnetsql_address" {
  type = list(string)
  default = [ "10.1.4.0/16" ]
}




