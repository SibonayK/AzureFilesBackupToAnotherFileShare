

Write-Host "Starting ...."
#Install-Module -Name Az -AllowClobber -Scope AllUsers

# Define Variables
$targetsubscriptionId = "7823e5c9-9c8d-4214-b814-e18363bfb850"
$sourcesubscriptionId = "7823e5c9-9c8d-4214-b814-e18363bfb850"
$targetstorageAccountRG = "renashdiybackuprg"
$sourcestorageAccountRG = "renashdiybackuprg"
$targetstorageAccountName = "renashdiybackupsa"
$sourcestorageAccountName = "renashdiybackupsa"
$targetstoragefileshareName = "target"
$sourcestoragefileshareName = "source"
$azcopypath = ".\azcopy"
# TODO - Change to cert based auth - https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-authenticate-service-principal-powershell#provide-certificate-through-automated-powershell-script-
$spAppPassword = "myVerySecurePassword1234!"
$spTenantId = "475ce392-90cc-4e97-94b5-028213916c6f"
$spAppId = "b0db7c9d-a3b2-4bbc-9b10-b0f15f35ae20"

# SOURCE
# Connect to Azure
$passwd = ConvertTo-SecureString $spAppPassword -AsPlainText -Force
$pscredential = New-Object System.Management.Automation.PSCredential($spAppId, $passwd)
# TODO - If this step fails, check  access control for the storage account. Under role assignment, give contributor access to the app id
Connect-AzAccount -ServicePrincipal -Credential $pscredential -Tenant $spTenantId -Subscription $sourcesubscriptionId

# Get Storage Account Key
$sourcestorageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $sourcestorageAccountRG -Name $sourcestorageAccountName).Value[0]

# Set AzStorageContext
$sourceContext = New-AzStorageContext -StorageAccountKey $sourcestorageAccountKey -StorageAccountName $sourcestorageAccountName

# Snapshot source share
$sourceshare = Get-AzStorageShare -Context $sourceContext.Context -Name $sourcestoragefileshareName
$sourcesnapshot = $sourceshare.CloudFileShare.Snapshot()

# Generate source Snapshot SAS URI
$sourceSASURIBasePermission = New-AzStorageAccountSASToken -Context $sourceContext -Service File -ResourceType Service,Container,Object -Permission "racwdlup"  -ExpiryTime (get-date).AddMonths(60) -StartTime (get-date).AddSeconds(-100)
$sourceSASURI = $sourceContext.FileEndPoint.ToString() + $sourceSASURIBasePermission.Replace('?',($sourcesnapshot.SnapshotQualifiedUri.PathAndQuery.Substring(1) + "&"))

# TARGET
# Select right Azure Subscription
Select-AzSubscription -subscriptionId $targetsubscriptionId

# Get Storage Account Key
$targetstorageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $targetstorageAccountRG -Name $targetstorageAccountName).Value[0]

# Set AzStorageContext
$destinationContext = New-AzStorageContext -StorageAccountKey $targetstorageAccountKey -StorageAccountName $targetstorageAccountName


# Generate target SAS URI
$targetSASURI = New-AzStorageShareSASToken -Context $destinationContext -ExpiryTime(get-date).AddMonths(60) -FullUri -Name $targetstoragefileshareName -Permission rcwdl


# logic to download newer copy of azcopy when available
# Invoke-WebRequest https://azcopyvnext.azureedge.net/release20190517/azcopy_windows_amd64_10.1.2.zip -OutFile azcopyv10.zip $azcopypath

# Upload File using AzCopy
Set-Location -Path $azcopypath
$azcopyout = $azcopypath sync $sourceSASURI $targetSASURI  --preserve-smb-info --preserve-smb-permissions --recursive=true
Write-Output $azcopyout

# Snapshot target share
$targetshare = Get-AzStorageShare -Context $destinationContext -Name $targetstoragefileshareName
$targetshare.CloudFileShare.Snapshot()

# TODO - For standardization, make error handling, logging, parameterization and retries like in https://github.com/Azure/azure-docs-powershell-samples/blob/master/storage/migrate-blobs-between-accounts/migrate-blobs-between-accounts.ps1
