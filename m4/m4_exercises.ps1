#Prefix for resources
$prefix = "cmk"

#Basic variables
$location = "eastus"
$id = Get-Random -Minimum 1000 -Maximum 9999

#Log into Azure
Add-AzAccount

#Select the correct subscription
Get-AzSubscription -SubscriptionName "SUB_NAME" | Select-AzSubscription

#If you already have a Key Vault
$keyVault = Get-AzKeyVault -VaultName "VAULT_NAME" -ResourceGroupName "RESOURCE_GROUP_NAME"

#Create a resource group for Key Vault
$keyVaultGroup = New-AzResourceGroup -Name "$prefix-key-vault-$id" -Location $location

#Create a new Key Vault
$keyVaultParameters = @{
    Name = "$prefix-key-vault-$id"
    ResourceGroupName = $keyVaultGroup.ResourceGroupName
    Location = $location
    Sku = "Standard"
}

$keyVault = New-AzKeyVault @keyVaultParameters

#######################################################
# STORAGE ACCCOUNT EXERCISE
#######################################################

#Create a new storage account
$saAccountParameters = @{
    Name = "$($prefix)sa$id"
    ResourceGroupName = $keyVaultGroup.ResourceGroupName
    Location = $location
    SkuName = "Standard_LRS"
}

$storageAccount = New-AzStorageAccount @saAccountParameters

Get-AzStorageAccountKey -ResourceGroupName $storageAccount.ResourceGroupName -Name $storageAccount.StorageAccountName

# Grant the Key Vault App Id the permissions on the storage account

$roleAssignment = @{
    ApplicationId = "cfa8b339-82a2-471a-a3c9-0fc0be7a4093"
    RoleDefinitionName = 'Storage Account Key Operator Service Role'
    Scope = $storageAccount.Id
}

New-AzRoleAssignment @roleAssignment

# Add your storage account to your Key Vault's managed storage accounts
$managedStorageAccount = @{
    VaultName = $keyVault.VaultName
    AccountName = $storageAccount.StorageAccountName
    AccountResourceId = $storageAccount.Id
    ActiveKeyName = "key1"
    RegenerationPeriod = [System.Timespan]::FromDays(90)
}

Add-AzKeyVaultManagedStorageAccount @managedStorageAccount

Get-AzKeyVaultManagedStorageAccount -VaultName $keyVault.VaultName

# Regenerate the key
$updateKeyParams = @{
    VaultName = $keyVault.VaultName
    AccountName = $storageAccount.StorageAccountName
    KeyName = "key1"
}

Update-AzKeyVaultManagedStorageAccountKey @updateKeyParams

#######################################################
# SOFT-DELETE AND PURGE EXERCISE
#######################################################

# Create a secret in Key Vault

$SecureStringValue = ConvertTo-SecureString -String 'QWERTyhnbV^54rtyhU&*76tgbnji*&6yh' -AsPlainText -Force

$secretParams = @{
  VaultName = $keyVault.VaultName
  Name = "TopSecret"
  SecretValue = $SecureStringValue
  NotBefore = (Get-Date).AddDays(30).ToUniversalTime()
  Expires = (Get-Date).AddYears(1).ToUniversalTime()
  ContentType = "API-Key"
}

Set-AzKeyVaultSecret @secretParams

# Delete the secret

Remove-AzKeyVaultSecret -VaultName $keyVault.VaultName -Name "TopSecret" -Force

# Recover the secret

Get-AzKeyVaultSecret $keyVault.VaultName -InRemovedState

Undo-AzKeyVaultSecretRemoval -VaultName $keyVault.VaultName -Name "TopSecret"

# Delete the secret

Remove-AzKeyVaultSecret -VaultName $keyVault.VaultName -Name "TopSecret" -Force

# Purge the secret - requires special permission!

Remove-AzKeyVaultSecret -VaultName $keyVault.VaultName -Name "TopSecret" -InRemovedState -Force

# Enable purge protection

$updateKeyVault = @{
    ResourceGroupName = $keyVaultGroup.ResourceGroupName
    VaultName = $keyVault.VaultName
    EnablePurgeProtection = $true
}

Update-AzKeyVault @updateKeyVault

#######################################################
# BACKUP AND RECOVER EXERCISE
#######################################################

# Recreate the secret

Set-AzKeyVaultSecret @secretParams

# Backup the secret locally

$backupParams = @{
  VaultName = $keyVault.VaultName
  Name = "TopSecret"
  OutputFile = "TopSecret.bkp"
}

Backup-AzKeyVaultSecret @backupParams

Get-Content .\TopSecret.bkp

# Create a new Key Vault in another region

$location = "westus"
$id++

#Create a resource group for Key Vault
$keyVaultGroup = New-AzResourceGroup -Name "$prefix-key-vault-$id" -Location $location

#Create a new Key Vault
$keyVaultParameters = @{
    Name = "$prefix-key-vault-$id"
    ResourceGroupName = $keyVaultGroup.ResourceGroupName
    Location = $location
    Sku = "Standard"
}

$keyVault2 = New-AzKeyVault @keyVaultParameters

Restore-AzKeyVaultSecret -VaultName $keyVault2.VaultName -InputFile .\TopSecret.bkp