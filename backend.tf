terraform {
  backend "azurerm" {
    resource_group_name  = "tf-state-rg"
    storage_account_name = "tfstateiury" # <-- Use the same unique name from Step A
    container_name       = "tfstate"
    key                  = "hml.terraform.tfstate"
  }
}