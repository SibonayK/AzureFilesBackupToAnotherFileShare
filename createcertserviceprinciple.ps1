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
Write-Output $sp.DisplayName
Write-Output $sp.ApplicationId
$tenantId = (Get-AzContext).Tenant.Id
Write-Output $tenantId