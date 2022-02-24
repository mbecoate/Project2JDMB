
#tags
variable "tags" {
    description = "Tags to use."
    type = map(string)
    default = {}
}

variable "rg" {
    description = "Resource Group to add to."
    type  = string
}
variable "rglocation" {
    description = "location of rg"
    type = string
}


#Networking Variables
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