# Script to create deployments for Azure OAI resource

# # Login to Azure
# Connect-AzAccount

Write-Host -ForegroundColor Blue "Reading in variables.."
$envFile = Get-Content -Path "variables.env"
$envFile | ForEach-Object {
    $keyValue = $_ -split "=", 2
    [Environment]::SetEnvironmentVariable($keyValue[0], $keyValue[1], "Process")
}

$resourceGroupName = $Env:RESOURCE_GROUP
$oaiResource = $Env:OAI_RESOURCE
$location = $Env:LOCATION
$oaiEndpoint = Get-AzCognitiveServicesAccount -ResourceGroupName $resourceGroupName -Name $oaiResource | Select-Object -Property endpoint
$oaiKey = Get-AzCognitiveServicesAccountKey -Name $oaiResource -ResourceGroupName $resourceGroupName | Select-Object -Property Key1
$availableModels = Get-AzCognitiveServicesModel -Location $location | where{$_.kind -eq "openai"} | select -ExpandProperty ModelProperty | select name

Function New-AzureOpenAIModel{
    Param(
        $modelName,
        $modelVersion
    )
    ##
    $modelProperties = New-AzCognitiveServicesObject -Type DeploymentProperties
    $modelProperties.Model.Format = "OpenAI"
    $modelProperties.Model.Name = "$modelName"
    $modelProperties.Model.Version = "$modelVersion"
    $modelSku = New-AzCognitiveServicesObject -Type Sku
    $modelSku.name = "Standard"
    $modelSku.Capacity = "50"
    New-AzCognitiveServicesAccountDeployment `
     -ResourceGroupName $resourceGroupName `
     -AccountName $oaiResource `
     -Name "$modelName" `
     -Properties $modelProperties `
     -Sku $modelSku
}

Write-Host -ForegroundColor Blue "Available models: \n $availableModels"

Write-Host -ForegroundColor Blue "Creating model deployment for gpt-4-o...."
New-AzureOpenAIModel -modelName "gpt-4o" -modelVersion "2024-05-13"

Write-Host -ForegroundColor Blue "Creating model deployment for text-embedding-ada-002...."
New-AzureOpenAIModel -modelName "text-embedding-ada-002" -modelVersion "2"
