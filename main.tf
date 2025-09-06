# Configuração do provider AzureRM
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

# Grupo de Recursos
resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
}

# Rede Virtual (VNet)
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = var.vnet_address_prefixes
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Subnet
resource "azurerm_subnet" "snet" {
  name                 = var.snet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.snet_address_prefixes

  # Explicitly set network policies to match existing state and prevent drift.
  # This is important for resources like Private Endpoints.
  private_endpoint_network_policies_enabled = false
  private_link_service_network_policies_enabled = true
}

resource "random_string" "suffix" {
  length  = 4
  lower   = true
  numeric = true
  special = false
  upper   = false
}

resource "azurerm_storage_account" "storage" {
  name                          = "${var.storage_name}${random_string.suffix.result}"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  access_tier                   = var.access_tier
  # For better security, consider setting public_network_access to "Disabled" and using private endpoints.
  public_network_access_enabled = var.public_network_access == "Enabled"
  allow_nested_items_to_be_public = var.allow_blob_public_access
  https_traffic_only_enabled    = true
  min_tls_version               = "TLS1_2"
}

locals {
  storage_containers = {
    "auditoria"      = "container"
    "brasao"         = "container"
    "facialRecogn"   = "container"
    "profile"        = "container"
    "shared-files"   = "container"
    "templates"      = "container"
    "utilitarios"    = "container"
    "tutorial"       = "container"
    "public-files"   = "blob"
    "apps"           = "blob"
    "images"         = "blob"
  }
}

# Containers
resource "azurerm_storage_container" "containers" {
  for_each = local.storage_containers

  name                  = each.key
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = each.value
}

# Cluster AKS
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.aks_dns_name_prefix
  kubernetes_version  = var.aks_kubernetes_version

  # Pool de nós padrão
  default_node_pool {
    name                = "nodepool1"
    node_count          = var.aks_default_node_pool_count
    vm_size             = var.aks_default_node_pool_vm_size
    vnet_subnet_id      = azurerm_subnet.snet.id
  }


  # Identidade gerenciada
  identity {
    type = "SystemAssigned"
  }

  # Configuração de rede
  network_profile {
    network_plugin    = "azure"
    dns_service_ip    = var.dns_service_ip
    service_cidr      = var.service_cidr
    load_balancer_sku = "standard"
  }

  tags = {
    Environment = "Homologacao"
  }
}

# Pool de nós adicional
resource "azurerm_kubernetes_cluster_node_pool" "elastic" {
  name                  = "nodeelastic"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  node_count            = var.aks_user_node_pool_count
  vm_size               = var.aks_user_node_pool_vm_size
  vnet_subnet_id        = azurerm_subnet.snet.id
}

# Referência à VNet existente em outro grupo de recursos
data "azurerm_virtual_network" "globalservice" {
  # NOTE: The name must match the existing VNet. Your state file shows it is "custodia_vnet_globalservice".
  name                = "custodia_vnet_globalservice"
  resource_group_name = var.global_rg_name
}

# Peering: vnet_tf-hml -> vnet_globalservice
resource "azurerm_virtual_network_peering" "aks_to_globalservice" {
  name                      = "${azurerm_virtual_network.vnet.name}-to-${data.azurerm_virtual_network.globalservice.name}"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  remote_virtual_network_id = data.azurerm_virtual_network.globalservice.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# Peering: vnet_globalservice -> vnet_tf-hml
resource "azurerm_virtual_network_peering" "globalservice_to_aks" {
  name                      = "${data.azurerm_virtual_network.globalservice.name}-to-${azurerm_virtual_network.vnet.name}"
  resource_group_name       = var.global_rg_name
  virtual_network_name      = data.azurerm_virtual_network.globalservice.name
  remote_virtual_network_id = azurerm_virtual_network.vnet.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# Outputs
output "aks_cluster_name" {
  description = "The name of the created AKS cluster."
  value       = azurerm_kubernetes_cluster.aks.name
}

output "aks_resource_group" {
  description = "The name of the resource group where the AKS cluster is located."
  value       = azurerm_kubernetes_cluster.aks.resource_group_name
}  

output "storage_account_name" {
  description = "The name of the created storage account."
  value       = azurerm_storage_account.storage.name
}