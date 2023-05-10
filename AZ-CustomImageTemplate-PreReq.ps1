# Check if Az module is installed
$AzModule = Get-InstalledModule -Name Az -ErrorAction SilentlyContinue

if ($AzModule) {
    # Get the latest version available in the PowerShell Gallery
    $LatestVersion = (Find-Module -Name Az).Version
    
    if ($AzModule.Version -lt $LatestVersion) {
        # Update the Az module
        Write-Host "Updating the Az module to the latest version ($LatestVersion)..."
        Update-Module -Name Az -Force
    } else {
        Write-Host "Az module is already up-to-date (version: $($AzModule.Version))."
    }
} else {
    # Install the Az module
    Write-Host "Installing the Az module..."
    Install-Module -Name Az -AllowClobber -Scope CurrentUser
}

# Conenct to Azure
Connect-AzAccount

# Set subscription
$subscriptionID = Read-Host "Enter Subscription ID"
Set-AzContext -Subscription $subscriptionID

# Array resource providers
$resourceProviders = @(
    'Microsoft.DesktopVirtualization',
    'Microsoft.VirtualMachineImages',
    'Microsoft.Storage',
    'Microsoft.Compute',
    'Microsoft.Network',
    'Microsoft.KeyVault'
)

# Loop through array and register the providers
foreach ($provider in $resourceProviders) {
    Register-AzResourceProvider -ProviderNamespace $provider
    Write-Host "Registered Resource Provider: $provider"
}

# Create a new resource group
$resourceGroupName = "rg-test-avdImageTemplate-001"
$location = Read-Host "Enter Location Name, e.g. UK South"
New-AzResourceGroup -Name $resourceGroupName -Location $location

# Create a user-assigned managed identity
$managedIdentityName = "mi-test-avdaib-001"
New-AzUserAssignedIdentity -ResourceGroupName $resourceGroupName -Name $managedIdentityName -Location $location

# Create a custom RBAC role
$roleName = "AzureImageBuilder"
$roleDescription = "Custom role with specific permissions for image management"
$roleDefinition = @{
    "Name" = $roleName
    "IsCustom" = $true
    "Description" = $roleDescription
    "Actions" = @(
        "Microsoft.Compute/galleries/read",
        "Microsoft.Compute/galleries/images/read",
        "Microsoft.Compute/galleries/images/versions/read",
        "Microsoft.Compute/galleries/images/versions/write",
        "Microsoft.Compute/images/write",
        "Microsoft.Compute/images/read",
        "Microsoft.Compute/images/delete"
    )
    "AssignableScopes" = @("/subscriptions/$subscriptionID")
}

$roleDefinitionObject = New-Object -TypeName 'Microsoft.Azure.Commands.Resources.Models.Authorization.PSRoleDefinition' -Property $roleDefinition
New-AzRoleDefinition -Role $roleDefinitionObject

# Pause to allow Azure resources propagation
Start-Sleep -Seconds 15

# Assign the custom RBAC role to the managed identity
$managedIdentity = Get-AzUserAssignedIdentity -ResourceGroupName $resourceGroupName -Name $managedIdentityName
$role = Get-AzRoleDefinition -Name $roleName
New-AzRoleAssignment -ObjectId $managedIdentity.PrincipalId -RoleDefinitionId $role.Id -Scope "/subscriptions/$subscriptionID"