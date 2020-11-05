#Log into Azure with CLI
az login
az account set --subscription "SUB_NAME"

id=$(((RANDOM%9999+1)))
prefix="cmk"
location="eastus"
resource_group="$prefix-key-vault-$id"
key_vault_name="$prefix-key-vault-$id"

#Create an Azure Key Vault
az group create -n $resource_group -l $location
az keyvault create -n $key_vault_name -g $resource_group \
  -l $location --sku Standard

# Grant access to keys and secrets for a user
az keyvault set-policy --name $key_vault_name \
  --upn "CaJoyce@contosohq.xyz" \
  --resource-group $resource_group \
  --secret-permissions get list set \
  --key-permissions get list create import

# Configure Key Vault Firewall Policies

# Get your public IP address
resp=$(curl https://ifconfig.me/ip)

az keyvault update --name $key_vault_name \
  --resource-group $resource_group \
  --set properties.networkAcls.bypass=AzureServices \
    properties.networkAcls.defaultAction=Deny

az keyvault network-rule add --name $key_vault_name \
  --resource-group $resource_group --ip-address $resp