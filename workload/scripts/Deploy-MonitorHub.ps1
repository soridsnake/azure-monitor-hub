<#
.SYNOPSIS
    Deploy Azure Monitor Hub Accelerator

.DESCRIPTION
    This script deploys the Azure Monitor Hub solution including:
    - Log Analytics Workspace
    - Data Collection Rules
    - Alert Rules
    - Action Groups
    - VM Monitoring Dashboard
    - Azure Policy for auto-enrollment

.PARAMETER SubscriptionId
    Azure Subscription ID where resources will be deployed

.PARAMETER DeploymentName
    Unique name for this deployment (used as prefix for resources)

.PARAMETER Location
    Azure region for deployment

.PARAMETER UseExistingResourceGroup
    Use an existing Resource Group instead of creating new one

.PARAMETER ExistingResourceGroupName
    Name of existing Resource Group (if UseExistingResourceGroup is true)

.PARAMETER UseExistingLogAnalytics
    Use an existing Log Analytics Workspace

.PARAMETER ExistingLogAnalyticsWorkspaceId
    Resource ID of existing Log Analytics Workspace

.PARAMETER EmailRecipients
    Semicolon-separated email addresses for alert notifications

.PARAMETER WhatIf
    Preview the deployment without actually deploying

.EXAMPLE
    .\Deploy-MonitorHub.ps1 -SubscriptionId "xxx-xxx-xxx" -DeploymentName "prod-monitoring" -Location "westeurope" -EmailRecipients "admin@company.com"

.EXAMPLE
    .\Deploy-MonitorHub.ps1 -SubscriptionId "xxx-xxx-xxx" -DeploymentName "prod-monitoring" -Location "westeurope" -UseExistingLogAnalytics -ExistingLogAnalyticsWorkspaceId "/subscriptions/xxx/resourceGroups/rg-logs/providers/Microsoft.OperationalInsights/workspaces/law-central" -EmailRecipients "admin@company.com;ops@company.com"

#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-z0-9-]{3,24}$')]
    [string]$DeploymentName,

    [Parameter(Mandatory = $true)]
    [string]$Location,

    [Parameter(Mandatory = $false)]
    [switch]$UseExistingResourceGroup,

    [Parameter(Mandatory = $false)]
    [string]$ExistingResourceGroupName,

    [Parameter(Mandatory = $false)]
    [switch]$UseExistingLogAnalytics,

    [Parameter(Mandatory = $false)]
    [string]$ExistingLogAnalyticsWorkspaceId,

    [Parameter(Mandatory = $false)]
    [int]$RetentionInDays = 90,

    [Parameter(Mandatory = $false)]
    [switch]$MonitorExistingVMs = $true,

    [Parameter(Mandatory = $false)]
    [string[]]$SelectedVMIds = @(),

    [Parameter(Mandatory = $false)]
    [switch]$AutoEnrollNewVMs = $true,

    [Parameter(Mandatory = $false)]
    [switch]$EnableCPUAlerts = $true,

    [Parameter(Mandatory = $false)]
    [ValidateRange(50, 95)]
    [int]$CPUThreshold = 85,

    [Parameter(Mandatory = $false)]
    [switch]$EnableMemoryAlerts = $true,

    [Parameter(Mandatory = $false)]
    [ValidateRange(50, 95)]
    [int]$MemoryThreshold = 85,

    [Parameter(Mandatory = $false)]
    [switch]$EnableDiskAlerts = $true,

    [Parameter(Mandatory = $false)]
    [ValidateRange(70, 95)]
    [int]$DiskThreshold = 85,

    [Parameter(Mandatory = $false)]
    [switch]$EnableHeartbeatAlerts = $true,

    [Parameter(Mandatory = $false)]
    [switch]$CreateActionGroup = $true,

    [Parameter(Mandatory = $false)]
    [string]$ActionGroupName = "ag-$DeploymentName",

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(;[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})*$')]
    [string]$EmailRecipients,

    [Parameter(Mandatory = $false)]
    [switch]$DeployDashboard = $true,

    [Parameter(Mandatory = $false)]
    [string]$DashboardName = "VM Monitoring Dashboard",

    [Parameter(Mandatory = $false)]
    [hashtable]$Tags = @{}
)

# Script variables
$ErrorActionPreference = "Stop"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$bicepPath = Join-Path (Split-Path $scriptPath -Parent) "bicep"
$mainBicepFile = Join-Path $bicepPath "deploy.bicep"

# Helper Functions
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        'Info'    { 'Cyan' }
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error'   { 'Red' }
    }
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Test-Prerequisites {
    Write-Log "Checking prerequisites..." -Level Info
    
    # Check if Azure PowerShell is installed
    if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
        Write-Log "Azure PowerShell module not found. Please install it: Install-Module -Name Az -AllowClobber -Scope CurrentUser" -Level Error
        exit 1
    }
    
    # Check if Bicep CLI is installed
    try {
        $bicepVersion = bicep --version 2>$null
        if (-not $bicepVersion) {
            throw
        }
        Write-Log "Bicep CLI found: $bicepVersion" -Level Success
    }
    catch {
        Write-Log "Bicep CLI not found. Please install it: https://learn.microsoft.com/azure/azure-resource-manager/bicep/install" -Level Error
        exit 1
    }
    
    # Check if main Bicep file exists
    if (-not (Test-Path $mainBicepFile)) {
        Write-Log "Main Bicep file not found at: $mainBicepFile" -Level Error
        exit 1
    }
    
    Write-Log "Prerequisites check completed successfully" -Level Success
}

function Connect-ToAzure {
    Write-Log "Connecting to Azure..." -Level Info
    
    try {
        $context = Get-AzContext
        if (-not $context) {
            Write-Log "No Azure context found. Please login..." -Level Warning
            Connect-AzAccount
        }
        
        # Set subscription context
        Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
        $subscription = Get-AzSubscription -SubscriptionId $SubscriptionId
        Write-Log "Connected to subscription: $($subscription.Name) ($SubscriptionId)" -Level Success
    }
    catch {
        Write-Log "Failed to connect to Azure: $_" -Level Error
        exit 1
    }
}

function Get-ExistingVMs {
    Write-Log "Discovering Virtual Machines in subscription..." -Level Info
    
    try {
        $vms = Get-AzVM
        
        if ($vms.Count -eq 0) {
            Write-Log "No Virtual Machines found in subscription" -Level Warning
            return @()
        }
        
        Write-Log "Found $($vms.Count) Virtual Machine(s)" -Level Success
        
        # Display VMs
        $vms | ForEach-Object {
            Write-Host "  - $($_.Name) (Resource Group: $($_.ResourceGroupName), Location: $($_.Location))" -ForegroundColor Gray
        }
        
        # Ask user if they want to select specific VMs
        $selectVMs = Read-Host "`nDo you want to select specific VMs to monitor? (Y/N) [Default: All]"
        
        if ($selectVMs -eq 'Y' -or $selectVMs -eq 'y') {
            $selectedVMs = @()
            foreach ($vm in $vms) {
                $monitor = Read-Host "Monitor $($vm.Name)? (Y/N) [Default: Y]"
                if ($monitor -ne 'N' -and $monitor -ne 'n') {
                    $selectedVMs += $vm.Id
                }
            }
            return $selectedVMs
        }
        else {
            return $vms | ForEach-Object { $_.Id }
        }
    }
    catch {
        Write-Log "Failed to discover VMs: $_" -Level Error
        return @()
    }
}

function Build-BicepParameters {
    param(
        [string[]]$VMIds
    )
    
    Write-Log "Building deployment parameters..." -Level Info
    
    $parameters = @{
        deploymentName = $DeploymentName
        location = $Location
        useExistingResourceGroup = $UseExistingResourceGroup.IsPresent
        existingResourceGroupName = $ExistingResourceGroupName
        useExistingLogAnalytics = $UseExistingLogAnalytics.IsPresent
        existingLogAnalyticsWorkspaceId = $ExistingLogAnalyticsWorkspaceId
        logAnalyticsWorkspaceName = "law-$DeploymentName"
        retentionInDays = $RetentionInDays
        monitorExistingVMs = $MonitorExistingVMs.IsPresent
        selectedVMIds = $VMIds
        autoEnrollNewVMs = $AutoEnrollNewVMs.IsPresent
        enableCPUAlerts = $EnableCPUAlerts.IsPresent
        cpuThreshold = $CPUThreshold
        enableMemoryAlerts = $EnableMemoryAlerts.IsPresent
        memoryThreshold = $MemoryThreshold
        enableDiskAlerts = $EnableDiskAlerts.IsPresent
        diskThreshold = $DiskThreshold
        enableHeartbeatAlerts = $EnableHeartbeatAlerts.IsPresent
        createActionGroup = $CreateActionGroup.IsPresent
        actionGroupName = $ActionGroupName
        emailRecipients = $EmailRecipients
        deployDashboard = $DeployDashboard.IsPresent
        dashboardName = $DashboardName
        tagsByResource = $Tags
    }
    
    return $parameters
}

function Start-Deployment {
    param(
        [hashtable]$Parameters
    )
    
    Write-Log "Starting deployment..." -Level Info
    Write-Log "Deployment Name: $DeploymentName" -Level Info
    Write-Log "Location: $Location" -Level Info
    
    if ($PSCmdlet.ShouldProcess($DeploymentName, "Deploy Azure Monitor Hub")) {
        try {
            $deploymentParams = @{
                Name = "MonitorHub-$DeploymentName-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
                Location = $Location
                TemplateFile = $mainBicepFile
                TemplateParameterObject = $Parameters
                Verbose = $true
            }
            
            $deployment = New-AzSubscriptionDeployment @deploymentParams
            
            if ($deployment.ProvisioningState -eq 'Succeeded') {
                Write-Log "Deployment completed successfully!" -Level Success
                return $deployment
            }
            else {
                Write-Log "Deployment failed with state: $($deployment.ProvisioningState)" -Level Error
                return $null
            }
        }
        catch {
            Write-Log "Deployment failed: $_" -Level Error
            Write-Log "Error details: $($_.Exception.Message)" -Level Error
            return $null
        }
    }
}

function Show-DeploymentResults {
    param(
        [object]$Deployment
    )
    
    if (-not $Deployment) {
        return
    }
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  DEPLOYMENT COMPLETED SUCCESSFULLY" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    $outputs = $Deployment.Outputs
    
    Write-Host "📊 Deployment Outputs:" -ForegroundColor Cyan
    Write-Host "  Resource Group: $($outputs.resourceGroupName.Value)" -ForegroundColor White
    Write-Host "  Log Analytics Workspace: $($outputs.logAnalyticsWorkspaceName.Value)" -ForegroundColor White
    Write-Host "  Workspace ID: $($outputs.logAnalyticsWorkspaceId.Value)" -ForegroundColor Gray
    
    if ($outputs.actionGroupId.Value) {
        Write-Host "  Action Group: Created" -ForegroundColor White
    }
    
    if ($outputs.dashboardUrl.Value) {
        Write-Host "`n🎨 Dashboard URL:" -ForegroundColor Cyan
        Write-Host "  $($outputs.dashboardUrl.Value)" -ForegroundColor Yellow
    }
    
    Write-Host "`n✅ Next Steps:" -ForegroundColor Cyan
    Write-Host "  1. Wait 5-10 minutes for data to start flowing" -ForegroundColor White
    Write-Host "  2. Open the Dashboard URL above to view VM status" -ForegroundColor White
    Write-Host "  3. Check your email for alert notifications" -ForegroundColor White
    Write-Host "  4. Review the deployed resources in the Azure Portal`n" -ForegroundColor White
}

# Main Script Execution
function Main {
    Write-Host @"

╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║          🖥️  AZURE MONITOR HUB ACCELERATOR  🖥️            ║
║                                                           ║
║     Automated VM Monitoring & Alerting Solution          ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan
    
    # Step 1: Prerequisites
    Test-Prerequisites
    
    # Step 2: Connect to Azure
    Connect-ToAzure
    
    # Step 3: Discover VMs (if monitoring existing VMs)
    $vmIds = $SelectedVMIds
    if ($MonitorExistingVMs -and $vmIds.Count -eq 0) {
        $vmIds = Get-ExistingVMs
    }
    
    # Step 4: Build parameters
    $parameters = Build-BicepParameters -VMIds $vmIds
    
    # Step 5: Deploy
    $deployment = Start-Deployment -Parameters $parameters
    
    # Step 6: Show results
    Show-DeploymentResults -Deployment $deployment
}

# Execute
Main