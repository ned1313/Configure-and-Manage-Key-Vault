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

# Assign Key Vault Contributor to an existing user

az role definition list --name "Key Vault Contributor"

vaultId=$(az keyvault show -g $resource_group -n $key_vault_name | jq -r .id)

az role assignment create --role "Key Vault Contributor" \
  --assignee "USER_PRINCIPAL_NAME" --scope $vaultId

#Get the current subscription ID and create the custom role json
subId=$(az account show | jq -r .id)
sed s/SUBSCRIPTION_ID/$subId/g custom_role.json > updated_role.json

#Get the role ID, vault ID, and user ID
role=$(az role definition create --role-definition updated_role.json)
user=$(az ad user show  --id "CaJoyce@contosohq.xyz" | jq -r .objectId)

#Assign the role to the user with the vault as the scope
az role assignment create --role "Secret Reader" \
  --assignee $user --scope $vaultId

