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

# Grant access to keys and secrets for a user

$accessPolicySettings = @{
    VaultName = $keyVault.VaultName
    ResourceGroupName = $keyVault.ResourceGroupName
    PermissionsToSecrets = @("get","list","set")
    PermissionsToKeys = @("get","list","create","import")
    UserPrincipalName = "USER_PRINCIPAL_NAME"
}

Set-AzKeyVaultAccessPolicy @accessPolicySettings

# Configure Key Vault Firewall Policies

# Get your public IP address
$resp = Invoke-WebRequest -Uri "https://ifconfig.me/ip"

$networkRuleSettings = @{
    DefaultAction = "Deny"
    Bypass = "AzureServices"
    VaultName = $keyVault.VaultName
    ResourceGroupName = $keyVault.ResourceGroupName
    IpAddressRange = $resp.Content
}

Update-AzKeyVaultNetworkRuleSet @networkRuleSettings