#Log into Azure with CLI
az login
az account set --subscription "SUB_NAME"

id=$(((RANDOM%9999+1)))
prefix="cmk"
location="eastus"
resource_group="$prefix-key-vault-$id"
key_vault_name="$prefix-key-vault-$id"
storage_account_name="${prefix}sa$id"

#Create an Azure Key Vault
az group create -n $resource_group -l $location
az keyvault create -n $key_vault_name -g $resource_group \
  -l $location --sku Standard

#######################################################
# STORAGE ACCCOUNT EXERCISE
#######################################################

#Create a new storage account
az storage account create -n $storage_account_name -g $resource_group \
  -l $location --sku Standard_LRS

az storage account keys list -g $resource_group -n $storage_account_name

sa_id=$(az storage account show -n $storage_account_name | jq -r .id)

# Grant the Key Vault App Id the permissions on the storage account

az role assignment create --role "Storage Account Key Operator Service Role" \
  --assignee 'https://vault.azure.net' --scope $sa_id

# Add your storage account to your Key Vault's managed storage accounts
# Might fail the first time as Azure AD propogates permissions
az keyvault storage add --vault-name $key_vault_name \
  -n $storage_account_name \
  --active-key-name key1 \
  --auto-regenerate-key --regeneration-period P90D \
  --resource-id $sa_id

az keyvault storage list --vault-name $key_vault_name

az storage account keys list -g $resource_group -n $storage_account_name

# Regenerate the key
az keyvault storage regenerate-key --vault-name $key_vault_name \
  --name $storage_account_name --key-name key1

az storage account keys list -g $resource_group -n $storage_account_name

#######################################################
# SOFT-DELETE AND PURGE EXERCISE
#######################################################

# Create a secret in Key Vault
expire=$(date -d "$(date --utc) +1 year" +%Y-%m-%d'T'%T'Z')
not_before=$(date -d "$(date --utc) +1 month" +%Y-%m-%d'T'%T'Z')

az keyvault secret set --vault-name $key_vault_name \
  --name "TopSecret" \
  --not-before $not_before \
  --expires $expire \
  --value 'QWERTyhnbV^54rtyhU&*76tgbnji*&6yh'

# Delete the secret
az keyvault secret delete --vault-name $key_vault_name \
  --name "TopSecret"

# Recover the secret

az keyvault secret list-deleted --vault-name $key_vault_name

az keyvault secret recover --vault-name $key_vault_name \
  --name "TopSecret"

# Delete the secret
az keyvault secret delete --vault-name $key_vault_name \
  --name "TopSecret"

# Purge the secret - requires special permission!

az keyvault secret purge --vault-name $key_vault_name \
  --name "TopSecret"

# Enable purge protection

az keyvault update --name $key_vault_name \
  --enable-purge-protection

# Recreate the secret

az keyvault secret set --vault-name $key_vault_name \
  --name "TopSecret" \
  --not-before $not_before \
  --expires $expire \
  --value 'QWERTyhnbV^54rtyhU&*76tgbnji*&6yh'

#######################################################
# BACKUP AND RECOVER EXERCISE
#######################################################

# Backup the secret locally

az keyvault secret backup --vault-name $key_vault_name \
  --name "TopSecret" \
  --file TopSecret.bkp

cat TopSecret.bkp

# Create a new Key Vault in another region

id2=$(((RANDOM%9999+1)))
location2="westus"
resource_group2="$prefix-key-vault-$id2"
key_vault_name2="$prefix-key-vault-$id2"

# Create an Azure Key Vault
az group create -n $resource_group2 -l $location2
az keyvault create -n $key_vault_name2 -g $resource_group2 \
  -l $location2 --sku Standard

# Restore the secret to new Key Vault

az keyvault secret restore --vault-name $key_vault_name2 \
  --file TopSecret.bkp