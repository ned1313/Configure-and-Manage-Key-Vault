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

# Create a key in Key Vault

$keyParams = @{
  VaultName = $keyVault.VaultName
  Name = "RSAKey"
  Destination = "Software"
  Expires = (Get-Date).AddYears(1).ToUniversalTime()
  KeyOps = @("decrypt","encrypt")
}

Add-AzKeyVaultKey @keyParams


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

# Now let's update the secret value
$SecureStringValue = ConvertTo-SecureString -String 'NBVGhji876tGBVFR567*IJHGT^%yhgt5(&YHJHY&' -AsPlainText -Force

$secretParams = @{
  VaultName = $keyVault.VaultName
  Name = "TopSecret"
  SecretValue = $SecureStringValue
}

Set-AzKeyVaultSecret @secretParams

Get-AzKeyVaultSecret -VaultName $keyvault.VaultName -Name "TopSecret" -IncludeVersions

# Create a self-signed certificate
$policyParams = @{
  SecretContentType = "application/x-pkcs12"
  SubjectName = "CN=www.surfingcow.xyz"
  IssuerName = "Self"
  ValidityInMonths = 12
}
$Policy = New-AzKeyVaultCertificatePolicy @policyParams

$certParams = @{
  VaultName = $keyVault.VaultName
  Name = "SurfingCow-www-cert"
  CertificatePolicy = $Policy
}
Add-AzKeyVaultCertificate @certParams

Get-AzKeyVaultCertificate -VaultName $keyVault.VaultName -Name "SurfingCow-www-cert"

Get-AzKeyVaultKey -VaultName $keyVault.VaultName -Name "SurfingCow-www-cert"

Get-AzKeyVaultSecret -VaultName $keyVault.VaultName -Name "SurfingCow-www-cert"