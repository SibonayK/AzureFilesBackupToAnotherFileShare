# This script generates a self-signed cert in the cert store on your local machine
# it then registers a new app in Azure Active directory with this cert authentication
# the new app assumes a contributor role on your subscription (you may narrow the access down further)
# finally it outputs the 

$ApplicationDisplayName = "renashdiyfilesbkcertapp12345"
$SubscriptionId = "7823e5c9-9c8d-4214-b814-e18363bfb850"
$CertPath = "cert:\CurrentUser\My"
$CertName = "CN=renashazfilebkpappScriptCert"

$cert = New-SelfSignedCertificate -CertStoreLocation $CertPath `
  -Subject $CertName`
  -KeySpec KeyExchange -Provider “Microsoft Enhanced RSA and AES Cryptographic Provider”
$keyValue = [System.Convert]::ToBase64String($cert.GetRawCertData())
Disconnect-AzAccount
Connect-AzAccount -Subscription $SubscriptionId
$sp = New-AzADServicePrincipal -DisplayName $ApplicationDisplayName -CertValue $keyValue
Sleep 20
$newRole = New-AzRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $sp.ApplicationId
Write-Output "Registered application name " $sp.DisplayName
Write-Output "Registered application ID " $sp.ApplicationId
$tenantId = (Get-AzContext).Tenant.Id
Write-Output "Your subscription tenant id " $tenantId