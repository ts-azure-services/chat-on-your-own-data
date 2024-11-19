# chat on your own data
Powershell scripts to support creation of resources and assignment of RBAC
permissions to leverage the 'chat on your data' functionality in the Azure
OpenAI Studio and Azure AI Studio. Once created, the user can then manually use the workflows to upload files or go through the Azure "blob storage" workflow. If manually uploading files, turn on CORS and enable blob anonymous access in the Configuration of the storage account.

## Caveats
- When provisioning, be mindful of the region and whether there is model quota for the OAI deployments. The scripts default to `southcentralus` for all resources.
- For developer permissions, you will likely need `Owner` or `Contributor` access.
- Before executing the `setup.ps1` file, you will need to update the user
  attribute for the "User Principal Name" of the developer from the Azure Portal, under Microsoft Entra ID. Also, ensure the
  subscription that defaults after logging in is the correct one.
