#Script to upload files

# # Login to Azure
# Connect-AzAccount

Write-Host -ForegroundColor Blue "Reading in variables.."
$envFile = Get-Content -Path "variables.env"
$envFile | ForEach-Object {
    $keyValue = $_ -split "=", 2
    [Environment]::SetEnvironmentVariable($keyValue[0], $keyValue[1], "Process")
}

$storageAccountName = $Env:STORAGE_ACCOUNT_NAME
$containerName = $Env:CONTAINER_NAME
$directoryPath = "data"
$ctx = New-AzStorageContext -StorageAccountName $storageAccountName -UseConnectedAccount

Write-Host -ForegroundColor Blue "Upload files into the container..."
Get-ChildItem -Path $directoryPath -File | ForEach-Object {
    $filePath = $_.FullName
    $blobName = $_.Name
    Set-AzStorageBlobContent -File $filePath -Container $containerName -Blob $blobName -Context $ctx
    if ($?) {
    Write-Host -ForegroundColor Green "Upload successful."
    }
  else
  {
    Write-Host -ForegroundColor Yellow "Error: Did not complete a successful upload."
    }
}
