
$ApplicationDisplayName = "renashdiyfilesbkcertapp1234"
$SubscriptionId = "7823e5c9-9c8d-4214-b814-e18363bfb850"
$CertPath = "my"
$CertPlainPassword = "1234"


$cert = New-SelfSignedCertificate -CertStoreLocation "cert:\CurrentUser\My" `
  -Subject "CN=renashazfilebkpappScriptCert" `
  -KeySpec KeyExchange
$keyValue = [System.Convert]::ToBase64String($cert.GetRawCertData())

Connect-AzAccount -Subscription $SubscriptionId

$sp = New-AzADServicePrincipal -DisplayName renashazfilebkpapp `
  -CertValue $keyValue `
  -EndDate $cert.NotAfter `
  -StartDate $cert.NotBefore
Sleep 20
$ newRole = New-AzRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $sp.ApplicationId
 (Get-AzSubscription -SubscriptionName "Visual Studio Ultimate with MSDN (7823e5c9-9c8d-4214-b814-e18363bfb850) -").TenantId
 (Get-AzADApplication -DisplayNameStartWith {$ApplicationDisplayName}).ApplicationId
