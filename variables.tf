variable "subscription_id" {
  description = "The Azure subscription ID where resources will be deployed."
  type = string
}

variable "tenant_id" {
  description = "The Azure tenant ID for authentication."
  type = string
}

variable "rg_name" {
  description = "The name of the main resource group."
  type = string
}

variable "location" {
  description = "The Azure region for resource deployment."
  type = string
}

variable "vnet_name" {
  description = "The name of the virtual network."
  type = string
}

variable "snet_name" {
  description = "The name of the subnet."
  type = string
}

variable "vnet_address_prefixes" {
  description = "A list of address prefixes for the virtual network."
  type = list(string)
}

variable "snet_address_prefixes" {
  description = "A list of address prefixes for the subnet."
  type = list(string)
}

variable "public_network_access" {
  type    = string
  default = "Enabled"
  description = "Controls public network access to the storage account. Can be 'Enabled' or 'Disabled'."

  validation {
    condition     = contains(["Enabled", "Disabled"], var.public_network_access)
    error_message = "The public_network_access must be either 'Enabled' or 'Disabled'."
  }
}


# Variáveis do Kubernetes
variable "dns_service_ip" {
  description = "The IP address for the DNS service within the AKS cluster."
  type = string
}

variable "service_cidr" {
  description = "The CIDR block for services within the AKS cluster."
  type = string
}

variable "aks_dns_name_prefix" {
  description = "The DNS prefix for the AKS cluster's FQDN."
  type = string
}

variable "global_rg_name" {
  description = "GlobalService"
  type        = string
}

variable "aks_cluster_name" {
  description = "The name for the AKS cluster."
  type        = string
  default     = "arck-tf-hml"
}

variable "aks_kubernetes_version" {
  description = "The version of Kubernetes to use for the AKS cluster. Run 'az aks get-versions --location <location> -o table' to see available versions."
  type        = string
  default     = "1.29.3" # Please verify this is available in your region
}

variable "aks_default_node_pool_count" {
  description = "The initial number of nodes for the default node pool."
  type        = number
  default     = 1
}

variable "aks_default_node_pool_vm_size" {
  description = "The VM size for the default node pool."
  type        = string
  default     = "Standard_B2s"
}

variable "aks_user_node_pool_count" {
  description = "The initial number of nodes for the user node pool."
  type        = number
  default     = 1
}

variable "aks_user_node_pool_vm_size" {
  description = "The VM size for the user node pool."
  type        = string
  default     = "Standard_B2s"
}
