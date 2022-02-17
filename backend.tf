terraform {
  backend "azurerm" {
    resource_group_name  = "JD_Main"
    storage_account_name = "jdmainstorage"
    container_name       = "terraform"
    key                  = "JDMBsecret"
  }
}