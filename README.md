# Infraestrutura Azure com Terraform para AKS (HML)

## Descrição

Este projeto Terraform provisiona uma infraestrutura base na Microsoft Azure para um ambiente de homologação (HML). Ele cria os seguintes recursos principais:
- Um Grupo de Recursos para organizar todos os serviços.
- Uma Rede Virtual (VNet) e uma Subnet dedicada.
- Uma Conta de Armazenamento (Storage Account) com vários contêineres pré-configurados.
- Um cluster Azure Kubernetes Service (AKS) com um pool de nós padrão e um pool de nós de usuário.
- Emparelhamento (Peering) de VNet entre a VNet recém-criada e uma VNet de serviços globais existente.

O estado do Terraform é gerenciado remotamente em uma conta de armazenamento do Azure para colaboração e segurança.

## Pré-requisitos

Antes de começar, certifique-se de que você tem o seguinte:
1.  **[Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)** (versão ~>1.0)
2.  **[Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)**
3.  Uma **subscrição do Azure** ativa.
4.  Autenticação na sua conta do Azure via CLI: `az login`
5.  **Recursos para o Backend Remoto**: O grupo de recursos, a conta de armazenamento e o contêiner para armazenar o arquivo de estado do Terraform (`.tfstate`) devem existir antes da execução. O arquivo `backend.tf` está configurado para usar:
    *   Resource Group: `tf-state-rg`
    *   Storage Account: `tfstateiury`
    *   Container Name: `tfstate`
6.  **VNet Global Existente**: Uma VNet chamada `custodia_vnet_globalservice` deve existir no grupo de recursos `GlobalService` para que o emparelhamento de rede seja bem-sucedido.

## Configuração

### 1. Backend Remoto

O arquivo `backend.tf` está configurado para armazenar o estado do Terraform no Azure. Se os recursos de backend ainda não existirem, você pode criá-los com os seguintes comandos da Azure CLI:

```bash
# Nome da sua subscrição
AZURE_SUBSCRIPTION_ID="<your-subscription-id>"
# Nome do grupo de recursos para o estado
RG_STATE_NAME="tf-state-rg"
# Localização
LOCATION="Brazil South" # ou sua localização preferida
# Nome da conta de armazenamento (deve ser único globalmente)
STORAGE_ACCOUNT_STATE_NAME="tfstateiury"
# Nome do container
CONTAINER_STATE_NAME="tfstate"

az account set --subscription $AZURE_SUBSCRIPTION_ID

# Criar grupo de recursos
az group create --name $RG_STATE_NAME --location "$LOCATION"

# Criar conta de armazenamento
az storage account create --name $STORAGE_ACCOUNT_STATE_NAME --resource-group $RG_STATE_NAME --location "$LOCATION" --sku Standard_LRS --encryption-services blob

# Criar container
az storage container create --name $CONTAINER_STATE_NAME --account-name $STORAGE_ACCOUNT_STATE_NAME
```
**Nota:** O nome da conta de armazenamento (`storage_account_name`) em `backend.tf` deve ser globalmente único. Altere `tfstateiury` se necessário.

### 2. Variáveis de Entrada

Crie um arquivo chamado `terraform.tfvars` na raiz do projeto para fornecer os valores para as variáveis necessárias. Use o exemplo abaixo como um template.

**terraform.tfvars.example:**
```hcl
# Credenciais e Assinatura Azure
subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
tenant_id       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# Configurações do Grupo de Recursos e Localização
rg_name  = "arck-tf-hml-rg"
location = "Brazil South"

# Configurações de Rede
vnet_name             = "arck-tf-hml-vnet"
snet_name             = "arck-tf-hml-snet"
vnet_address_prefixes = ["10.1.0.0/16"]
snet_address_prefixes = ["10.1.1.0/24"]

# Configurações da Conta de Armazenamento
storage_name = "arcktfhmlstorage" # Um sufixo aleatório será adicionado

# Configurações do Cluster AKS
dns_service_ip      = "10.2.0.10"
service_cidr        = "10.2.0.0/24"
aks_dns_name_prefix = "arck-tf-hml-aks"
aks_cluster_name    = "arck-tf-hml-cluster"

# Nome do Grupo de Recursos da VNet Global
global_rg_name = "GlobalService"
```

## Como Usar

Após configurar o backend e as variáveis, siga os passos padrão do Terraform.

1.  **Inicializar o Terraform**
    Este comando inicializa o diretório de trabalho, baixando os providers e configurando o backend.
    ```bash
    terraform init
    ```

2.  **Planejar as Mudanças**
    Este comando cria um plano de execução. É uma boa prática revisar o plano antes de aplicá-lo para garantir que as mudanças estão de acordo com o esperado.
    ```bash
    terraform plan -out=tfplan
    ```

3.  **Aplicar as Mudanças**
    Este comando aplica as mudanças descritas no plano para criar ou atualizar a infraestrutura no Azure.
    ```bash
    terraform apply "tfplan"
    ```

## Destruindo a Infraestrutura

Para remover todos os recursos criados por este projeto, execute o comando `destroy`.

**AVISO:** Este comando é destrutivo e removerá permanentemente sua infraestrutura. Use com cuidado.

```bash
terraform destroy
```

## Recursos Criados

-   `azurerm_resource_group`: Grupo de recursos principal.
-   `azurerm_virtual_network`: Rede virtual para o ambiente.
-   `azurerm_subnet`: Sub-rede para os recursos, incluindo os nós do AKS.
-   `azurerm_storage_account`: Conta de armazenamento para uso geral.
-   `azurerm_storage_container`: Múltiplos contêineres dentro da conta de armazenamento.
-   `azurerm_kubernetes_cluster`: O cluster AKS principal.
-   `azurerm_kubernetes_cluster_node_pool`: Um pool de nós adicional para o cluster.
-   `azurerm_virtual_network_peering`: Emparelhamento de rede em ambas as direções entre a VNet do AKS e a VNet global.

## Entradas (Inputs)

| Nome | Descrição | Tipo | Padrão | Obrigatório |
| --- | --- | --- | --- | --- |
| `subscription_id` | ID da subscrição do Azure onde os recursos serão implantados. | `string` | - | Sim |
| `tenant_id` | ID do tenant do Azure para autenticação. | `string` | - | Sim |
| `rg_name` | O nome do grupo de recursos principal. | `string` | - | Sim |
| `location` | A região do Azure para implantação dos recursos. | `string` | - | Sim |
| `vnet_name` | O nome da rede virtual. | `string` | - | Sim |
| `snet_name` | O nome da sub-rede. | `string` | - | Sim |
| `vnet_address_prefixes` | Uma lista de prefixos de endereço para a rede virtual. | `list(string)` | - | Sim |
| `snet_address_prefixes` | Uma lista de prefixos de endereço para a sub-rede. | `list(string)` | - | Sim |
| `storage_name` | O nome base para a conta de armazenamento. Um sufixo aleatório será adicionado. | `string` | - | Sim |
| `access_tier` | O nível de acesso para a conta de armazenamento. Pode ser 'Hot' ou 'Cool'. | `string` | `"Cool"` | Não |
| `public_network_access` | Controla o acesso da rede pública à conta de armazenamento. Pode ser 'Enabled' ou 'Disabled'. | `string` | `"Enabled"` | Não |
| `allow_blob_public_access` | Se permite acesso público anônimo de leitura a blobs na conta de armazenamento. | `bool` | `true` | Não |
| `dns_service_ip` | O endereço IP para o serviço DNS dentro do cluster AKS. | `string` | - | Sim |
| `service_cidr` | O bloco CIDR para serviços dentro do cluster AKS. | `string` | - | Sim |
| `aks_dns_name_prefix` | O prefixo DNS para o FQDN do cluster AKS. | `string` | - | Sim |
| `global_rg_name` | O nome do grupo de recursos onde a VNet global está localizada. | `string` | - | Sim |
| `aks_cluster_name` | O nome para o cluster AKS. | `string` | `"arck-tf-hml"` | Não |
| `aks_kubernetes_version` | A versão do Kubernetes a ser usada para o cluster AKS. | `string` | `"1.29.3"` | Não |
| `aks_default_node_pool_count` | O número inicial de nós para o pool de nós padrão. | `number` | `1` | Não |
| `aks_default_node_pool_vm_size` | O tamanho da VM para o pool de nós padrão. | `string` | `"Standard_B2s"` | Não |
| `aks_user_node_pool_count` | O número inicial de nós para o pool de nós de usuário. | `number` | `1` | Não |
| `aks_user_node_pool_vm_size` | O tamanho da VM para o pool de nós de usuário. | `string` | `"Standard_B2s"` | Não |

## Saídas (Outputs)

| Nome | Descrição |
| --- | --- |
| `aks_cluster_name` | O nome do cluster AKS criado. |
| `aks_resource_group` | O nome do grupo de recursos onde o cluster AKS está localizado. |
| `storage_account_name` | O nome da conta de armazenamento criada. |
