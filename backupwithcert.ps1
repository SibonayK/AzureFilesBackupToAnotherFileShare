$LogTime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
#  Log file name:
$LogFile = '.\LOG\'+"BACKUPLOG_"+$LogTime+".log"
Start-Transcript -InformationAction -path $LogFile -append
#Install-Module -Name Az -AllowClobber -Scope AllUsers
Write-Host "Starting ...."
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
# $spAppPassword = "myVerySecurePassword1234!"
$CertPath = "cert:\CurrentUser\My\"
$CertPlainPassword = "1234"
$ApplicationId = "9dbc6a13-34cf-4c88-97d5-789ea0307783"
$TenatId = "475ce392-90cc-4e97-94b5-028213916c6f"
#$spTenatId = "475ce392-90cc-4e97-94b5-028213916c6f"
#$spAppId = "4bfba36a-e902-4ede-8f7a-22968dc8bf63"

# SOURCE

# Connect to Azure

$CertPassword = ConvertTo-SecureString $CertPlainPassword -AsPlainText -Force
 $PFXCert = New-Object `
  -TypeName System.Security.Cryptography.X509Certificates.X509Certificate2 `
  -ArgumentList @($CertPath, $CertPassword)

 $PFXCert=Get-ChildItem  -Recurse -Path cert:\CurrentUser\My\ | where {$_.Subject -eq "CN=renashazfilebkpappScriptCert"}

 $Thumbprint = $PFXCert.Thumbprint

 Connect-AzAccount -ServicePrincipal `
  -CertificateThumbprint $Thumbprint `
  -ApplicationId $ApplicationId `
  -TenantId $TenantId -Subscription $SubscriptionId

  # Password based auth
# $passwd = ConvertTo-SecureString $spAppPassword -AsPlainText -Force
# $pscredential = New-Object System.Management.Automation.PSCredential($spAppId, $passwd)
# Connect-AzAccount -ServicePrincipal -Credential $pscredential -Tenant $spTenatId -Subscription $sourcesubscriptionId

# Get Storage Account Key
$sourcestorageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $sourcestorageAccountRG -Name $sourcestorageAccountName).Value[0]

# Set AzStorageContext
$sourceContext = New-AzStorageContext -StorageAccountKey $sourcestorageAccountKey -StorageAccountName $sourcestorageAccountName

# Snapshot source share
$sourceshare = Get-AzStorageShare -Context $sourceContext.Context -Name $sourcestoragefileshareName
$sourcesnapshot = $sourceshare.Snapshot()

# Generate source Snapshot SAS URI
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


# logic to download newer copy of azcopy when available
# Invoke-WebRequest https://azcopyvnext.azureedge.net/release20190517/azcopy_windows_amd64_10.1.2.zip -OutFile azcopyv10.zip $azcopypath

# Upload File using AzCopy
Set-Location -Path $azcopypath
$azcopyout = .\azcopy.exe sync $sourceSASURI $targetSASURI
Write-Output $azcopyout

# Snapshot target share
$targetshare = Get-AzStorageShare -Context $targetContext.Context -Name $targetstoragefileshareName
$targetshare.Snapshot()

# TODO - For standardization, make error handling, logging, parameterization and retries like in https://github.com/Azure/azure-docs-powershell-samples/blob/master/storage/migrate-blobs-between-accounts/migrate-blobs-between-accounts.ps1
Stop-Transcript

# Upload log file to destination file share
Set-AzStorageFileContent -Context $targetContext.Context -source $LogTime+".log" -ShareName $targetstoragefileshareName -Path "logfiles\" + $LogTime -PreserveSMBAttribute