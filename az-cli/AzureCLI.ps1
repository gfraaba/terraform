# # https://go.microsoft.com/fwlink/?linkid=2271236

# $SubscriptionId = '954cd2ab-618f-4856-9db9-9de24ee78bd6' # ISBEngineering Sub
az login --use-device-code
# az account set --subscription $SubscriptionId
$SubscriptionId = az account show --query id -o tsv
$RGName = 'RGP-CIPSU-AzOPS-EASTUS'

# Create a User Assigned Managed Identity
$UamiName = 'UAMI-AZOPS-APPSVC-ACR'
az identity create --resource-group $RGName --name $UamiName
$UamiId = az identity show --resource-group $RGName --name $UamiName --query id -o tsv
# id: This is the unique identifier for the managed identity resource itself within Azure. It is used to reference the managed identity resource in Azure Resource Manager (ARM) operations. This ID is specific to the Azure resource and is used for managing the resource.
# principalId (objectId): This is the unique identifier for the managed identity within Azure AD. It is used to reference the managed identity in Azure AD operations. It is used internally by Azure AD to identify the managed identity for authentication and authorization purposes.
# clientId: This is the application (client) ID of the managed identity in Azure Active Directory (AAD). It is used by applications to request tokens from Azure AD. When an application needs to authenticate itself to Azure AD to obtain an access token, it uses the clientId to identify itself. The clientId is often used in conjunction with a clientSecret (for service principals) or a certificate to authenticate the application.
# Summary: Use id when you need to manage the identity resource in Azure. Use principalId when you need to authenticate or authorize the identity in Azure AD. The application (client) ID of the managed identity in Azure AD, is used by applications to request tokens.

# Create a Log Analytics Workspace
$LawName = 'LAW-AZOPS-EASTUS'
az monitor log-analytics workspace create --resource-group $RGName --workspace-name $LawName
$LawId = az monitor log-analytics workspace show --resource-group $RGName --workspace-name $LawName --query id -o tsv
# # Update the retention period of the Log Analytics Workspace to 7 days - *NOTE: Couldn't change the default value of 30 days for 'Basic' sku (name = PerGB2018)!
# az monitor log-analytics workspace update --resource-group $RGName --workspace-name $LawName --retention-time 7 # Error: (InvalidParameter) 'RetentionInDays' property doesn't match the SKU limits.

# Create a Container Registry
$AcrName = 'acrazops'
az acr create --resource-group $RGName --name $AcrName --sku Basic --workspace $LawId --admin-enabled true # --admin-enabled parameter lets you push images to the registry using admin credentials
$AcrId = az acr show --resource-group $RGName --name $AcrName --query id -o tsv
# # Retrieve the admin credentials for the Container Registry
# az acr credential show --name $AcrName --resource-group $RGName --query "{username:username, password:passwords[0].value}" -o json

# # Docker login to the Container Registry
az acr login --name $AcrName # Now you can use Docker commands to push or pull images to ACR without needing to run docker login separately
# docker login ${AcrName}.azurecr.io -u $AcrName -p $(az acr credential show --name $AcrName --resource-group $RGName --query passwords[0].value -o tsv)

# Define the image details
$ImageName = 'sample-image' # Image names should only contain lowercase letters, numbers, hyphens, periods, and underscores
$ImageTag = 'latest'

# Verify authentication by pulling an image from ACR
docker pull ${AcrName}.azurecr.io/${ImageName}:${ImageTag} # "invalid reference format" error can mean the image isn't found in the registry
