# Script to invoke the Open AI api

# # Login to Azure
# Connect-AzAccount
function Invoke-OpenAIChatGPT4o{
    param(
        $question
    )
    $AZURE_OPENAI_API_KEY = (Get-AzCognitiveServicesAccountKey `
     -Name $oaiResource `
     -ResourceGroupName $resourceGroupName `
     | Select-Object -Property Key1).Key1
    $AZURE_OPENAI_ENDPOINT = (Get-AzCognitiveServicesAccount `
     -ResourceGroupName $resourceGroupName `
     -Name $oaiResource `
     |  Select-Object -Property endpoint).endpoint
    $headers = @{
        "api-key" = "$AZURE_OPENAI_API_KEY"
        "Content-Type" = "application/json"
    }
    $messages = @()
    $messages += @{
      role = 'user'
      content = "$question"
    }
    $body = [ordered]@{
       messages = $messages
    } | ConvertTo-Json
    $response = invoke-webrequest -method POST `
        -uri "$AZURE_OPENAI_ENDPOINT/openai/deployments/gpt-4o/chat/completions?api-version=2024-02-01" `
        -header $headers `
        -body $body
         | convertfrom-json `
         | select -ExpandProperty choices `
         | select -ExpandProperty message `
         | select content
    $response.content | fl *
}

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

Write-Host -ForegroundColor Blue "Testing an OAI response..."
$question = "Why is Pluto not a planet?"
Write-Host -ForegroundColor Blue "Question: $question"
Invoke-OpenAIChatGPT4o -question $question
