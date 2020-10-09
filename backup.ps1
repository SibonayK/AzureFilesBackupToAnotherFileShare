Write-Host "Starting ...."

# Define Variables
$sourcesubscriptionId = <SourceSubcriptionID>
$targetsubscriptionId = <TargetSubcriptionID>
$sourcestorageAccountRG = <SourceResourceGroup>
$targetstorageAccountRG = <TargetResourceGroup>
$sourcestorageAccountName = <SourceStorageAcccountName>
$targetstorageAccountName = <TargetStorageAcccountName>
$sourcestoragefileshareName = <SourceShareName>
$targetstoragefileshareName = <TargetShareName>
$azcopypath = <PathToAzCopy.exe>

# Variables defined when creating the service principal. These values were printed to the console in the service principal script. 
$spTenantId = <TenantID>
$spAppId = <AppID>
$certThumbprint = <CertificateThumbprint>

# SOURCE
# Connect to Azure
Connect-AzAccount -ServicePrincipal -Tenant $spTenantId -CertificateThumbprint $certThumbprint -ApplicationId $spAppId

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

# Upload File using AzCopy
Set-Location -Path $azcopypath
$azcopyout = $azcopypath sync $sourceSASURI $targetSASURI --preserve-smb-info --preserve-smb-permissions --recursive=true
Write-Output $azcopyout

# Snapshot target share
$targetshare = Get-AzStorageShare -Context $destinationContext -Name $targetstoragefileshareName
$targetshare.CloudFileShare.Snapshot()
