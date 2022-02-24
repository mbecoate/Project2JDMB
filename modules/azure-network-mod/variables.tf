
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
}
variable "vnet2location" {
    description = "location for seconed network"
    type = string
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
  default = ["10.0.0.0/16"]
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