# Run the script in a new open Powershell window, which has not run other cmdlets, or AzCopy performance could suffer .
# Need install Azure PowerShell before runing the script: https://docs.microsoft.com/en-us/azure/storage/common/storage-powershell-guide-full
# Need install AzCopy before runing the script: https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-v10
# Need to creeate Service principle and install the cert on the computer running this script
# Do not modify the Source or Destination accounts while the copy is running

# Define Variables
$sourcesubscriptionId = "157153da-0965-4353-8183-d6e5a52c92cb"
$targetsubscriptionId = "dd80b94e-0463-4a65-8d04-c94f403879dc"
$targetstorageAccountRG = "mydiybackuprg"
$sourcestorageAccountRG = "afslfsresourcegroup"
$targetstorageAccountName = "mydiybackupsa"
$sourcestorageAccountName = "afslfspfseastus2"
$targetstoragefileshareName = "target"
$sourcestoragefileshareName = "30tbfileshare"
$azcopypath = "F:\drop\drop\"
$CertPath = "cert:\CurrentUser\My\"
$CertName = "CN=myazfilebkpappScriptCert"
$ApplicationId = "2f75b54b-82df-4975-a5c5-6b938cbd5cd6"
$TenantId = "72f988bf-86f1-41af-91ab-2d7cd011db47"
$numsnapshotretention = 10

# Start Logging
$LogTime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
$LogFile = 'F:\LOG\'+"BACKUPLOG_"+$LogTime+".log"
Start-Transcript -Path $LogFile -Append

Write-Host "Starting Using task Scheduler...."

# SOURCE
$Error.Clear()

# Connect to Azure
$PFXCert=Get-ChildItem  -Recurse -Path $CertPath | where {$_.Subject -eq $CertName }
$Thumbprint = $PFXCert.Thumbprint

 Connect-AzAccount -ServicePrincipal `
  -CertificateThumbprint $Thumbprint `
  -ApplicationId $ApplicationId `
  -TenantId $TenantId -Subscription $sourcesubscriptionId

# Get Storage Account Key
$sourcestorageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $sourcestorageAccountRG -Name $sourcestorageAccountName).Value[0]

# Set AzStorageContext
$sourceContext = New-AzStorageContext -StorageAccountKey $sourcestorageAccountKey -StorageAccountName $sourcestorageAccountName

# Snapshot source share
$sourceshare = Get-AzStorageShare -Context $sourceContext.Context -Name $sourcestoragefileshareName
$sourcesnapshot = $sourceshare.Snapshot()

# Generate source Snapshot SAS URI
$sourceSASURIBasePermission = New-AzStorageAccountSASToken -Context $sourceContext.Context -Service File -ResourceType Service,Container,Object -Permission "racwdlup"  -ExpiryTime (get-date).AddMonths(60) -StartTime (get-date).AddSeconds(-100)
$sourceSASURI = $sourceContext.FileEndPoint.ToString() + $sourceSASURIBasePermission.Replace('?',($sourcesnapshot.SnapshotQualifiedUri.PathAndQuery.Substring(1) + "&"))

# TARGET
# Select right Azure Subscription
 Connect-AzAccount -ServicePrincipal `
  -CertificateThumbprint $Thumbprint `
  -ApplicationId $ApplicationId `
  -TenantId $TenantId -Subscription $targetsubscriptionId

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
$azcopyout = .\azcopy_windows_amd64.exe sync $sourceSASURI $targetSASURI
Write-Output $azcopyout

# Snapshot target share
$targetshare = Get-AzStorageShare -Context $destinationContext -Name $targetstoragefileshareName
$targetshare.Snapshot()

# TODO - For standardization, make error handling, logging, parameterization and retries like in https://github.com/Azure/azure-docs-powershell-samples/blob/master/storage/migrate-blobs-between-accounts/migrate-blobs-between-accounts.ps1
Stop-Transcript

# Upload log file to destination file share

Set-AzStorageFileContent -Context $sourceContext -source $LogFile -ShareName $sourcestoragefileshareName -PreserveSMBAttribute

# retain lastest n snapshots on source
$snapshots = Get-AzStorageShare -Context $sourceContext | where {$_.Name.Equals($sourcestoragefileshareName)} | where{ $_.IsSnapshot -eq $true }
$date = $sourcesnapshot.SnapshotTime
$snapshotToDelete = $null
do
{
  foreach ($s in $snapshots)
    {
        if ($s.Properties.LastModified.CompareTo($date) -lt 0 -and $snapshots.Count -gt $numsnapshotretention)
        {
            $snapshotToDelete = $s
            $date = $s.Properties.LastModified
        }
    }
Remove-AzStorageShare -Force -Name $snapshotToDelete.Name -Context $sourceContext
$snapshots = Get-AzStorageShare -Context $sourceContext | where {$_.Name.Equals($sourcestoragefileshareName)} | where{ $_.IsSnapshot -eq $true }
} while ($snapshots.Count -gt $numsnapshotretention)