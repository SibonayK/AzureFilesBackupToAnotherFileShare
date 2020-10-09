$sourcesubscriptionId = <sourceSubscriptionID>
$appidname = <AppID>

# Uncomment the line below if Az is not installed yet
#Install-Module -Name Az -AllowClobber -Scope AllUsers
Connect-AzAccount
Select-AzSubscription -subscriptionId $sourcesubscriptionId

# Create service principal using certificate-based authentication
$cert = New-SelfSignedCertificate -CertStoreLocation "cert:\CurrentUser\My"
  -Subject "CN=exampleappScriptCert" `
  -KeySpec KeyExchange
$keyValue = [System.Convert]::ToBase64String($cert.GetRawCertData())

$sp = New-AzADServicePrincipal -DisplayName $appidname 
-CertValue $keyValue 
Sleep 20
New-AzRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $sp.ApplicationId

# These values will be used to authenticate in the Backup script
Write-Output $cert.Thumbprint 
Write-Output $sp.DisplayName
Write-Output $sp.ApplicationId
$tenantId = (Get-AzContext).Tenant.Id
Write-Output $tenantId
