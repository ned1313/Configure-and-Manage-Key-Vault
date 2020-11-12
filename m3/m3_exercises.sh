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

# Create a key in Key Vault
expire=$(date -d "$(date --utc) +1 year" +%Y-%m-%d'T'%T'Z')

az keyvault key create --vault-name $key_vault_name \
  --expires $expire \
  --kty RSA \
  --name 'RSAKey' \
  --ops decrypt encrypt

# Create a secret in Key Vault
expire=$(date -d "$(date --utc) +1 year" +%Y-%m-%d'T'%T'Z')
not_before=$(date -d "$(date --utc) +1 month" +%Y-%m-%d'T'%T'Z')

az keyvault secret set --vault-name $key_vault_name \
  --name "TopSecret" \
  --not-before $not_before \
  --expires $expire \
  --value 'QWERTyhnbV^54rtyhU&*76tgbnji*&6yh'

# Now let's update the secret value
az keyvault secret set --vault-name $key_vault_name \
  --name "TopSecret" \
  --not-before $not_before \
  --expires $expire \
  --value 'NBVGhji876tGBVFR567*IJHGT^%yhgt5(&YHJHY&'

# List all versions of the secret
az keyvault secret list-versions \
  --name "TopSecret" --vault-name $key_vault_name

# Create a self-signed certificate
az keyvault certificate create --vault-name $key_vault_name \
  --name "SurfingCow-www-cert" \
  --policy @cert_policy.json

cert=$(az keyvault certificate show --vault-name $key_vault_name \
  --name "SurfingCow-www-cert")

key_id=$(echo $cert | jq .kid -r)
secret_id=$(echo $cert | jq .sid -r)

az keyvault key show --id $key_id

az keyvault secret show --id $secret_id