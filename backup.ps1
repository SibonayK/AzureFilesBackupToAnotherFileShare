Write-Host "Starting ...."
Install-Module -Name Az -AllowClobber -Scope AllUsers

# Define Variables
$targetsubscriptionId = "dd80b94e-0463-4a65-8d04-c94f403879dc"
$sourcesubscriptionId = "dd80b94e-0463-4a65-8d04-c94f403879dc"
$targetstorageAccountRG = "renashazcopyrg"
$sourcestorageAccountRG = "renashazcopyrg"
$targetstorageAccountName = "renashtargetazcopy"
$sourcestorageAccountName = "renashtargetazcopy"
$targetstoragefileshareName = "faketarget"
$sourcestoragefileshareName = "sourcefileshare"
$azcopypath = ".\azcopy"
$spAppPassword = "myVerySecurePassword1234!"
$spTenatId = "72f988bf-86f1-41af-91ab-2d7cd011db47"
$spAppId = "9c792091-549a-4463-a00c-3c4badb67f19"

# Connect to Azure
$passwd = ConvertTo-SecureString $spAppPassword -AsPlainText -Force
$pscredential = New-Object System.Management.Automation.PSCredential($spAppId, $passwd)
Connect-AzAccount -ServicePrincipal -Credential $pscredential -Tenant $spTenatId

# Select right Azure Subscription
Select-AzSubscription -subscriptionId $sourcesubscriptionId

# Get Storage Account Key
$sourcestorageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $sourcestorageAccountRG -Name $sourcestorageAccountName).Value[0]

# Set AzStorageContext
$sourceContext = New-AzStorageContext -StorageAccountKey $sourcestorageAccountKey -StorageAccountName $sourcestorageAccountName

# Snapshot source share
$sourceshare = Get-AzStorageShare -Context $sourceContext.Context -Name $sourcestoragefileshareName
$sourcesnapshot = $sourceshare.Snapshot()

# Generate source Snapshot SAS URI

# $sourceSASURI = New-AzStorageShareSASToken -Context $destinationContext -ExpiryTime(get-date).AddMonths(60) -FullUri -Name $sourcesnapshot.SnapshotQualifiedUri.PathAndQuery.Substring(1) -Permission rwdl -StartTime (get-date).AddSeconds(-100)
# $sourceSASURI = New-AzStorageShareSASToken -Context $destinationContext -ExpiryTime(get-date).AddMonths(60) -FullUri -Name $sourcestoragefileshareName -Permission rcwdl -StartTime (get-date).AddSeconds(-100)
$sourceSASURIBasePermission = New-AzStorageAccountSASToken -Context $destinationContext -Service File -ResourceType Service,Container,Object -Permission "racwdlup"  -ExpiryTime (get-date).AddMonths(60) -StartTime (get-date).AddSeconds(-100)
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


# TODO - logic to download newer copy of azcopy when available

# Upload File using AzCopy
# F:\azcopy_windows_amd64_10.3.3\azcopy_windows_amd64_10.3.3\azcopy sync $sourceSASURI $targetSASURI

$AzCopyCmd= $azcopypath+"\azcopy.exe sync " + $sourceSASURI + "  " +$targetSASURI

Invoke-Expression -command $AzCopyCmd

# Snapshot target share
$targetshare = Get-AzStorageShare -Context $targetContext.Context -Name $targetstoragefileshareName
$targetshare.Snapshot()