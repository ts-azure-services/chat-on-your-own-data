# Script to setup all necessary infra for chat on data in Azure AI Studio

# # Login to Azure
# Connect-AzAccount

Write-Host -ForegroundColor Blue "Check if Az.Search module installed..."
if (Get-Module -ListAvailable -Name "Az.Search") 
    { Write-Host "Module is installed." } 
else { 
Write-Host "Module is not installed. Proceeding to install it..."
  Install-Module Az.Search
}

# Variables
$rand_number = Get-Random
$resourceGroupName = "rg$rand_number"
$location = "southcentralus"
$storageAccountName = "storage$rand_number"
$searchServiceName = "search$rand_number"
$oaiResource = "oai$rand_number"
$containerName = "container$rand_number"
$user="<enter the User Principal Name, from Microsoft Entra ID in the Azure Portal>"


Write-Host -ForegroundColor Blue "Creating a resource group..."
New-AzResourceGroup -Name $resourceGroupName -Location $location
if ($?) {
  Write-Host -ForegroundColor Green "Created resource group."
  }
else
{
  Write-Host -ForegroundColor Yellow "Error: Did not create resource group."
  }

Write-Host -ForegroundColor Blue "Creating an Azure OAI resource..."
$oai_params = @{
	ResourceGroupName = $resourceGroupName
	Name = $oaiResource
	Location = $location
	Type = "OpenAI"
	SkuName = "S0"
	CustomSubdomainName = $oaiResource
}
$oai_resource = New-AzCognitiveServicesAccount @oai_params
if ($?) {
  Write-Host -ForegroundColor Green "Created Azure OAI resource."
  }
else
{
  Write-Host -ForegroundColor Yellow "Error: Did not create Azure OAI resource."
  }

Start-Sleep -Seconds 5


Write-Host -ForegroundColor Blue "Setting a managed identity for the OAI resource..."
$oai_params = @{
	ResourceGroupName = $resourceGroupName
	Name = $oaiResource
	IdentityType = "SystemAssigned"
}
$oai_resource = Set-AzCognitiveServicesAccount @oai_params
if ($?) {
  Write-Host -ForegroundColor Green "Set system managed identity for the Azure OAI resource."
  }
else
{
  Write-Host -ForegroundColor Yellow "Error: Could not set the system managed identity for the Azure OAI resource."
  }


Write-Host -ForegroundColor Blue "Retrieve the object ID of the Azure OAI resource managed identity..."
$oai_mi_objectid = (Get-AzResource -ResourceId $oai_resource.Id).Identity.PrincipalId


Write-Host -ForegroundColor Blue "Creating the storage account..."
$storage_params = @{
	ResourceGroupName = $resourceGroupName
	Name = $storageAccountName
	Location = $location
	SkuName = "Standard_LRS"
	Kind = "StorageV2"
	EnableHttpsTrafficOnly = $true
}
$storage_account = New-AzStorageAccount @storage_params
if ($?) {
  Write-Host -ForegroundColor Green "Created a storage account."
  }
else
{
  Write-Host -ForegroundColor Yellow "Error: Did not create a storage account."
  }
Start-Sleep -Seconds 5

Write-Host -ForegroundColor Blue "Creating a blob container in the storage account..."
$ctx = New-AzStorageContext -StorageAccountName $storageAccountName -UseConnectedAccount
$container = Get-AzStorageContainer -Name $containerName -Context $ctx -ErrorAction SilentlyContinue
if (-not $container) {
    New-AzStorageContainer -Name $containerName -Context $ctx
}
if ($?) {
  Write-Host -ForegroundColor Green "Created a blob container."
  }
else
{
  Write-Host -ForegroundColor Yellow "Error: Did not create a blob container."
  }


# Write-Host -ForegroundColor Blue "Enable CORS rules..."
# # $CorsRules = (@{
# # 	AllowedOrigins=@(*);
# # 	AllowedHeaders=@(*);
# # 	ExposedHeaders=@(*);
# # 	MaxAgeInSeconds=200;
# # 	AllowedMethods=@("Get","Post","Put","Connect");
# # })
# # Set-AzureStorageCORSRule -ServiceType Blob -CorsRules $CorsRules -Context $ctx
# az storage cors add --methods GET POST PUT OPTIONS --allowed-headers "*" --origins "*" --max-age 300 --services "b" --account-name $storageAccountName

Write-Host -ForegroundColor Blue "Creating the search account..."
$search_params = @{
	ResourceGroupName = $resourceGroupName
	Name = $searchServiceName
	Location = $location
	Sku = "Basic"
}
$search_service = New-AzSearchService @search_params
if ($?) {
  Write-Host -ForegroundColor Green "Created a search service."
  }
else
{
  Write-Host -ForegroundColor Yellow "Error: Did not create a search service."
  }

Start-Sleep -Seconds 5

Write-Host -ForegroundColor Blue "Enable a system managed identity and AuthOption = both for the search service..."
$search_update_params = @{
	Name = $searchServiceName
	ResourceGroupName = $resourceGroupName
	IdentityType = "SystemAssigned"
	AuthOption = "AadOrApiKey"
}
$search_service = Set-AzSearchService @search_update_params
if ($?) {
  Write-Host -ForegroundColor Green "Enabled a system managed identity and AuthOption = Both on the search service."
  }
else
{
  Write-Host -ForegroundColor Yellow "Error: Could not enable a system managed identity on the search service."
  }

Write-Host -ForegroundColor Blue "Retrieve the object ID of the Search service managed identity..."
$search_mi_objectid = (Get-AzResource -ResourceId $search_service.Id).Identity.PrincipalId

Start-Sleep -Seconds 5

# Set User or Developer perms

Write-Host -ForegroundColor Blue "Grant 'Storage Blob Data Contributor' to the user for upload of files..."
$rbac_assignments = @{
	SignInName = $user
	RoleDefinitionName = "Storage Blob Data Contributor"
	Scope = $storage_account.Id
}
New-AzRoleAssignment @rbac_assignments

Write-Host -ForegroundColor Blue "Grant 'Storage Blob Data Reader' to the user ..."
$rbac_assignments = @{
	SignInName = $user
	RoleDefinitionName = "Storage Blob Data Reader"
	Scope = $storage_account.Id
}
New-AzRoleAssignment @rbac_assignments


Write-Host -ForegroundColor Blue "Grant 'Cognitive Services OpenAI Contributor' access to the user..."
$rbac_assignments = @{
	SignInName = $user
	RoleDefinitionName = "Cognitive Services OpenAI Contributor"
	Scope = $oai_resource.Id
}
New-AzRoleAssignment @rbac_assignments


Write-Host -ForegroundColor Blue "Grant 'Cognitive Services User' access to the user..."
$rbac_assignments = @{
	SignInName = $user
	RoleDefinitionName = "Cognitive Services User"
	Scope = $oai_resource.Id
}
New-AzRoleAssignment @rbac_assignments

Write-Host -ForegroundColor Blue "Grant 'Cognitive Services Contributor' access to the user..."
$rbac_assignments = @{
	SignInName = $user
	RoleDefinitionName = "Cognitive Services Contributor"
	Scope = $oai_resource.Id
}
New-AzRoleAssignment @rbac_assignments

Write-Host -ForegroundColor Blue "Grant 'Search Service Contributor' access to the user..."
$rbac_assignments = @{
	SignInName = $user
	RoleDefinitionName = "Search Service Contributor"
	Scope = $search_service.Id
}
New-AzRoleAssignment @rbac_assignments

Write-Host -ForegroundColor Blue "Grant 'Search Index Data Reader' access to the user..."
$rbac_assignments = @{
	SignInName = $user
	RoleDefinitionName = "Search Index Data Reader"
	Scope = $search_service.Id
}
New-AzRoleAssignment @rbac_assignments


Write-Host -ForegroundColor Blue "Grant 'Search Index Data Contributor' access to the user..."
$rbac_assignments = @{
	SignInName = $user
	RoleDefinitionName = "Search Index Data Contributor"
	Scope = $search_service.Id
}
New-AzRoleAssignment @rbac_assignments

# Set RBAC permissions for other resources

Write-Host -ForegroundColor Blue "Grant 'Storage Blob Data Contributor' access to the Azure OAI resource..."
$rbac_assignments = @{
	ObjectId = $oai_mi_objectid
	RoleDefinitionName = "Storage Blob Data Contributor"
	Scope = $storage_account.Id
}
New-AzRoleAssignment @rbac_assignments

Write-Host -ForegroundColor Blue "Grant 'Search Service Contributor' access to the Azure OAI resource..."
$rbac_assignments = @{
	ObjectId = $oai_mi_objectid
	RoleDefinitionName = "Search Service Contributor"
	Scope = $search_service.Id
}
New-AzRoleAssignment @rbac_assignments

Write-Host -ForegroundColor Blue "Grant 'Search Index Data Reader' access to the Azure OAI resource..."
$rbac_assignments = @{
	ObjectId = $oai_mi_objectid
	RoleDefinitionName = "Search Index Data Reader"
	Scope = $search_service.Id
}
New-AzRoleAssignment @rbac_assignments

Write-Host -ForegroundColor Blue "Grant 'Search Index Data Contributor' access to the Azure OAI resource..."
$rbac_assignments = @{
	ObjectId = $oai_mi_objectid
	RoleDefinitionName = "Search Index Data Contributor"
	Scope = $search_service.Id
}
New-AzRoleAssignment @rbac_assignments

Write-Host -ForegroundColor Blue "Grant 'Cognitive Services OpenAI Contributor' access to the Search service..."
$rbac_assignments = @{
	ObjectId = $search_mi_objectid
	RoleDefinitionName = "Cognitive Services OpenAI Contributor"
	Scope = $oai_resource.Id
}
New-AzRoleAssignment @rbac_assignments

Write-Host -ForegroundColor Blue "Grant 'Cognitive Services Contributor' access to the Search service..."
$rbac_assignments = @{
	ObjectId = $search_mi_objectid
	RoleDefinitionName = "Cognitive Services Contributor"
	Scope = $oai_resource.Id
}
New-AzRoleAssignment @rbac_assignments

Write-Host -ForegroundColor Blue "Grant 'Storage Blob Data Contributor' access to the Search service..."
$rbac_assignments = @{
	ObjectId = $search_mi_objectid
	RoleDefinitionName = "Storage Blob Data Contributor"
	Scope = $storage_account.Id
}
New-AzRoleAssignment @rbac_assignments

Write-Host -ForegroundColor Blue "Grant 'Storage Blob Data Reader' access to the Search service..."
$rbac_assignments = @{
	ObjectId = $search_mi_objectid
	RoleDefinitionName = "Storage Blob Data Reader"
	Scope = $storage_account.Id
}
New-AzRoleAssignment @rbac_assignments

## Print out role assignments for validation
Write-Host -ForegroundColor Blue "Get role assignments for each resource to validate..."
$storage_assignments = Get-AzRoleAssignment -Scope $storage_account.Id
$search_assignments = Get-AzRoleAssignment -Scope $search_service.Id
$oai_assignments = Get-AzRoleAssignment -Scope $oai_resource.Id

$combined_assignments = $storage_assignments + $search_assignments + $oai_assignments

# Filter for specific role assignments, and Scope with the above resource group
$specific_roles = "Storage Blob Data Reader", "Cognitive Services OpenAI Contributor", "Search Index Data Reader", "Search Service Contributor", "Storage Blob Data Contributor", "Cognitive Services User", "Search Index Data Contributor", "Owner", "Contributor", "Cognitive Services Contributor"
$filtered_assignments = $combined_assignments | Where-Object { $specific_roles -contains $_.RoleDefinitionName }
$filtered_assignments = $filtered_assignments | Where-Object { $_.Scope -like "*$resourceGroupName*" }
$filtered_assignments | Format-Table -Property RoleDefinitionName, DisplayName, Scope

Write-Host -ForegroundColor Blue "Write out values to variables.env..."
$envFilePath = ".\variables.env"

$envContent = @"
RESOURCE_GROUP=$resourceGroupName
LOCATION=$location
OAI_RESOURCE=$oaiResource
STORAGE_ACCOUNT_NAME=$storageAccountName
CONTAINER_NAME=$containerName
"@

Set-Content -Path $envFilePath -Value $envContent
