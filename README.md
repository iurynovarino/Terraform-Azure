# Infraestrutura Azure com Terraform para AKS (HML)
 
## Descrição
 
Este projeto Terraform provisiona uma infraestrutura base na Microsoft Azure para um ambiente fictício de homologação (HML). A estrutura foi segmentada para operar como se houvesse uma rede principal que chamei de global, nessa camada operaria os recurso comuns entre os projetos. Já o cluster de HML rodará na rede de homologação onde por sua vez pensei em alocar todos os recursos desse ambiente de homologação, porém nesse projeto aqui foi focado somente no AKS. Abaixo estão os recursos pretendidos para subir com esse script do Terraform:

- Um Grupo de Recursos para organizar todos os serviços.
- Uma Rede Virtual (VNet) e uma Subnet dedicada.
- Um cluster Azure Kubernetes Service (AKS) com um pool de nós padrão e um pool de nós de usuário.
- Emparelhamento (Peering) de VNet entre a VNet recém-criada e uma VNet de serviços globais existente.
 
O estado do Terraform é gerenciado remotamente em uma conta de armazenamento do Azure para colaboração e segurança.
 
## Pré-requisitos
 
Antes de começar, certifique-se de que você tem o seguinte:
1.  **[Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)** (versão ~>1.0)
2.  **[Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)**
3.  Uma **subscrição do Azure** ativa.
4.  Autenticação na sua conta do Azure via CLI: `az login`
5.  **VNet Global Existente**: Uma VNet para emparelhamento deve existir. Por padrão, o código procura uma VNet chamada `vnet_globalservice` dentro do grupo de recursos `GlobalService`.
 
## Configuração
 
### Variáveis de Entrada

Nesse repositório há um arquivo chamado `terraform.tfvars` na raiz do projeto para fornecer os valores para as variáveis necessárias. Altere os atributos das variáveis de acordo com a sua necessidade.


## Como Usar

Após configurar as variáveis, siga os passos padrão do Terraform.

1.  **Inicializar o Terraform**
    Este comando inicializa o diretório de trabalho.
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



