# This script generates a self-signed cert in the cert store on your local machine
# it then registers a new app in Azure Active directory with this cert authentication
# the new app assumes a contributor role on your subscription (you may narrow the access down further)
# finally it outputs the 

$ApplicationDisplayName = "mydiyfilesbkcertapp12345"
$targetsubscriptionId = "dd80b94e-0463-4a65-8d04-c94f403879dc"
$sourcesubscriptionId = "157153da-0965-4353-8183-d6e5a52c92cb"
$CertPath = "cert:\CurrentUser\My"
$CertName = "CN=myazfilebkpappScriptCert"

$cert = New-SelfSignedCertificate -CertStoreLocation $CertPath `
  -Subject $CertName`
  -KeySpec KeyExchange -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider"
$keyValue = [System.Convert]::ToBase64String($cert.GetRawCertData())
Disconnect-AzAccount


# Source
Connect-AzAccount -Subscription $sourcesubscriptionId
$sp = New-AzADServicePrincipal -DisplayName $ApplicationDisplayName -CertValue $keyValue
Sleep 20
$newRole = New-AzRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $sp.ApplicationId
Write-Output "Registered application name " $sp.DisplayName
Write-Output "Registered application ID " $sp.ApplicationId
$tenantId = (Get-AzContext).Tenant.Id
Write-Output "Your subscription tenant id " $tenantId


# Target
Connect-AzAccount -Subscription $targetsubscriptionId
$newRole = New-AzRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $sp.ApplicationId
Write-Output "Registered application name " $sp.DisplayName
Write-Output "Registered application ID " $sp.ApplicationId
$tenantId = (Get-AzContext).Tenant.Id
Write-Output "Your subscription tenant id " $tenantId