# TODO - Change to cert based auth instead of password based auth  - https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-authenticate-service-principal-powershell#next-steps
$sourcesubscriptionId = "7823e5c9-9c8d-4214-b814-e18363bfb850"
$appidname = "renashdiyfilesbkapp"
$apppassword = "myVerySecurePassword1234!"
# Install-Module -Name Az -AllowClobber -Scope AllUsers
Connect-AzAccount
Select-AzSubscription -subscriptionId $sourcesubscriptionId
Import-Module Az.Resources # Imports the PSADPasswordCredential object
$credentials = New-Object Microsoft.Azure.Commands.ActiveDirectory.PSADPasswordCredential -Property @{ StartDate=Get-Date; EndDate=Get-Date -Year 2024; Password=$apppassword}
$sp = New-AzAdServicePrincipal -DisplayName $appidname -PasswordCredential $credentials
Write-Output $sp.DisplayName
Write-Output $sp.ApplicationId
$tenantId = (Get-AzContext).Tenant.Id
Write-Output $tenantId
