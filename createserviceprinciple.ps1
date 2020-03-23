$sourcesubscriptionId = "dd80b94e-0463-4a65-8d04-c94f403879dc"
$appidname = "renashdiyfilesbkapp"
$apppassword = "myVerySecurePassword1234!"

Select-AzSubscription -subscriptionId $sourcesubscriptionId
Import-Module Az.Resources # Imports the PSADPasswordCredential object
$credentials = New-Object Microsoft.Azure.Commands.ActiveDirectory.PSADPasswordCredential -Property @{ StartDate=Get-Date; EndDate=Get-Date -Year 2024; Password=$apppassword}
$sp = New-AzAdServicePrincipal -DisplayName $appidname -PasswordCredential $credentials
Write-Output $sp.DisplayName
Write-Output $sp.Id
$tenantId = (Get-AzContext).Tenant.Id
Write-Output $tenantId
