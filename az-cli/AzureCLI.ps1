# # https://learn.microsoft.com/en-us/cli/azure/cheat-sheet-onboarding
# # https://go.microsoft.com/fwlink/?linkid=2271236

# # To update your subscription list, use the az account clear command. You will need to sign in again to see an updated list.
# # Clearing your subscription cache is not technically the same process as logging out of Azure. However, when you clear your subscription cache, you cannot run Azure CLI commands, including az account set, until you sign in again.
# az account clear
az login --use-device-code
# az account set --subscription $SubscriptionId
# az account show --query "{subscriptionId:id, subscriptionName:name, tenantId:tenantId}" -o json
# az account list --query "[].{subscriptionId:id, subscriptionName:name, tenantId:tenantId}" -o json
$SubscriptionId = az account show --query id -o tsv
# # Get access token for the active subscription
# az account get-access-token
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

# # Azure Container Apps
# az containerapp up --name <CONTAINER_APP_NAME> --resource-group <RESOURCE_GROUP> --subscription <SUBSCRIPTION> --location <LOCATION> --environment <ENVIRONMENT_NAME> --artifact <WAR_FILE_PATH_AND_NAME> --build-env-vars BP_TOMCAT_VERSION=10.* --ingress external --target-port 8080 --query properties.configuration.ingress.fqdn
az extension list --output table
az extension add --name containerapp --upgrade --allow-preview
az extension show --name containerapp
$ContainerAppName = 'azops-container-app'
$Location = 'eastus'
$EnvironmentName = 'sandbox'
$ArtifactPath = '~/github/repos/spring-framework-petclinic/target/petclinic.war'

# TODO: Pass arguments related to ACR (registry server hostname, username, password) to the containerapp up command
az containerapp up `
    --name $ContainerAppName `
    --resource-group $RGName `
    --subscription $SubscriptionId `
    --location $Location `
    --environment $EnvironmentName `
    --artifact $ArtifactPath `
    --build-env-vars BP_TOMCAT_VERSION=10.* `
    --ingress external `
    --target-port 8080 `
    --logs-workspace-id $LawId `
    --query properties.configuration.ingress.fqdn

# containerapp up command includes the --query properties.configuration.ingress.fqdn argument, which returns the fully qualified domain name (FQDN), also known as the app's URL. You can use this URL to access the app in a web browser.
# http://azops-container-app.orangetree-f9c76f58.eastus.azurecontainerapps.io

# # Cleanup script to delete resources
# # List all Log Analytics Workspaces in the resource group
# az monitor log-analytics workspace list --resource-group $RGName --query "[].{Name:name, ID:id}" --output table

# # Replace 'LAW-AZOPS-EASTUS-1234' with the actual name of the automatically created LAW
# $AutoCreatedLawName = 'LAW-AZOPS-EASTUS-1234'  # Replace with the actual name

# # Delete the automatically created Log Analytics Workspace
# az monitor log-analytics workspace delete --resource-group $RGName --workspace-name $AutoCreatedLawName --yes

# # Delete the Log Analytics Workspace
# az monitor log-analytics workspace delete --resource-group $RGName --workspace-name $LawName --yes

# # Delete the Container Registry
# az acr delete --resource-group $RGName --name $AcrName --yes

# # Delete the User Assigned Managed Identity
# az identity delete --resource-group $RGName --name $UamiName

# # Delete the Azure Container App
# az containerapp delete --name $ContainerAppName --resource-group $RGName --yes

# # Delete the Container App Environment
# az containerapp env delete --name $EnvironmentName --resource-group $RGName --yes
