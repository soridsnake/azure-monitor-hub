targetScope = 'subscription'

@description('Deployment name')
param deploymentName string

@description('Azure region for resources')
param location string = deployment().location

@description('Use existing Resource Group')
param useExistingResourceGroup bool = false

@description('Existing Resource Group name')
param existingResourceGroupName string = ''

@description('Use existing Log Analytics Workspace')
param useExistingLogAnalytics bool = false

@description('Existing Log Analytics Workspace ID')
param existingLogAnalyticsWorkspaceId string = ''

@description('Log Analytics Workspace name')
param logAnalyticsWorkspaceName string

@description('Log retention in days')
param retentionInDays int = 90

@description('Monitor existing VMs')
param monitorExistingVMs bool = true

@description('Selected VM IDs to monitor')
param selectedVMIds array = []

@description('Auto-enroll new VMs')
param autoEnrollNewVMs bool = true

@description('Enable CPU alerts')
param enableCPUAlerts bool = true

@description('CPU threshold percentage')
param cpuThreshold int = 85

@description('Enable Memory alerts')
param enableMemoryAlerts bool = true

@description('Memory threshold percentage')
param memoryThreshold int = 85

@description('Enable Disk alerts')
param enableDiskAlerts bool = true

@description('Disk threshold percentage')
param diskThreshold int = 85

@description('Enable Heartbeat alerts')
param enableHeartbeatAlerts bool = true

@description('Create Action Group')
param createActionGroup bool = true

@description('Action Group name')
param actionGroupName string

@description('Email recipients (semicolon separated)')
param emailRecipients string

@description('Deploy monitoring dashboard')
param deployDashboard bool = true

@description('Dashboard name')
param dashboardName string = 'VM Monitoring Dashboard'

@description('Tags for resources')
param tagsByResource object = {}

// Variables
var resourceGroupName = useExistingResourceGroup ? existingResourceGroupName : 'rg-${deploymentName}'
var tags = {
  DeployedBy: 'Azure-Monitor-Hub'
  Environment: 'Production'
  ManagedBy: 'Bicep'
}

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = if (!useExistingResourceGroup) {
  name: resourceGroupName
  location: location
  tags: union(tags, contains(tagsByResource, 'Microsoft.Resources/resourceGroups') ? tagsByResource['Microsoft.Resources/resourceGroups'] : {})
}

// Get existing Resource Group if needed
resource existingRg 'Microsoft.Resources/resourceGroups@2024-03-01' existing = if (useExistingResourceGroup) {
  name: existingResourceGroupName
}

// Deploy Log Analytics Workspace
module logAnalytics 'modules/log-analytics.bicep' = if (!useExistingLogAnalytics) {
  name: 'deploy-log-analytics'
  scope: useExistingResourceGroup ? existingRg : rg
  params: {
    workspaceName: logAnalyticsWorkspaceName
    location: location
    retentionInDays: retentionInDays
    tags: union(tags, contains(tagsByResource, 'Microsoft.OperationalInsights/workspaces') ? tagsByResource['Microsoft.OperationalInsights/workspaces'] : {})
  }
}

// Get workspace ID (either new or existing)
var workspaceId = useExistingLogAnalytics ? existingLogAnalyticsWorkspaceId : logAnalytics.outputs.workspaceId
var workspaceResourceId = useExistingLogAnalytics ? existingLogAnalyticsWorkspaceId : logAnalytics.outputs.workspaceResourceId

// Deploy Data Collection Rules
module dataCollectionRules 'modules/data-collection-rules.bicep' = {
  name: 'deploy-dcr'
  scope: useExistingResourceGroup ? existingRg : rg
  params: {
    location: location
    workspaceResourceId: workspaceResourceId
    dcrName: 'dcr-${deploymentName}-vms'
    tags: union(tags, contains(tagsByResource, 'Microsoft.Insights/dataCollectionRules') ? tagsByResource['Microsoft.Insights/dataCollectionRules'] : {})
  }
  dependsOn: [
    logAnalytics
  ]
}

// Deploy Action Group
module actionGroup 'modules/action-group.bicep' = if (createActionGroup) {
  name: 'deploy-action-group'
  scope: useExistingResourceGroup ? existingRg : rg
  params: {
    actionGroupName: actionGroupName
    location: 'global'
    emailRecipients: emailRecipients
    tags: union(tags, contains(tagsByResource, 'Microsoft.Insights/actionGroups') ? tagsByResource['Microsoft.Insights/actionGroups'] : {})
  }
}

// Deploy Alert Rules
module alertRules 'modules/alert-rules.bicep' = if (createActionGroup) {
  name: 'deploy-alert-rules'
  scope: useExistingResourceGroup ? existingRg : rg
  params: {
    location: location
    workspaceResourceId: workspaceResourceId
    actionGroupId: createActionGroup ? actionGroup.outputs.actionGroupId : ''
    enableCPUAlerts: enableCPUAlerts
    cpuThreshold: cpuThreshold
    enableMemoryAlerts: enableMemoryAlerts
    memoryThreshold: memoryThreshold
    enableDiskAlerts: enableDiskAlerts
    diskThreshold: diskThreshold
    enableHeartbeatAlerts: enableHeartbeatAlerts
    alertNamePrefix: deploymentName
    tags: union(tags, contains(tagsByResource, 'Microsoft.Insights/scheduledQueryRules') ? tagsByResource['Microsoft.Insights/scheduledQueryRules'] : {})
  }
  dependsOn: [
    logAnalytics
    actionGroup
  ]
}

// Associate VMs with DCR
module vmAssociations 'modules/vm-associations.bicep' = if (monitorExistingVMs && length(selectedVMIds) > 0) {
  name: 'deploy-vm-associations'
  scope: useExistingResourceGroup ? existingRg : rg
  params: {
    vmIds: selectedVMIds
    dcrId: dataCollectionRules.outputs.dcrId
  }
  dependsOn: [
    dataCollectionRules
  ]
}

// Deploy Azure Policy for auto-enrollment (if enabled)
module autoEnrollPolicy 'modules/azure-policy.bicep' = if (autoEnrollNewVMs) {
  name: 'deploy-auto-enroll-policy'
  scope: subscription()
  params: {
    policyName: 'policy-${deploymentName}-auto-enroll'
    dcrId: dataCollectionRules.outputs.dcrId
    assignmentName: 'assign-${deploymentName}-auto-enroll'
    location: location
  }
  dependsOn: [
    dataCollectionRules
  ]
}

// Deploy Workbook Dashboard
module workbook 'modules/workbook.bicep' = if (deployDashboard) {
  name: 'deploy-workbook'
  scope: useExistingResourceGroup ? existingRg : rg
  params: {
    workbookName: dashboardName
    location: location
    workspaceResourceId: workspaceResourceId
    tags: union(tags, contains(tagsByResource, 'Microsoft.Insights/workbooks') ? tagsByResource['Microsoft.Insights/workbooks'] : {})
  }
  dependsOn: [
    logAnalytics
  ]
}

// Outputs
output resourceGroupName string = useExistingResourceGroup ? existingResourceGroupName : rg.name
output logAnalyticsWorkspaceId string = workspaceId
output logAnalyticsWorkspaceName string = useExistingLogAnalytics ? split(existingLogAnalyticsWorkspaceId, '/')[8] : logAnalytics.outputs.workspaceName
output dataCollectionRuleId string = dataCollectionRules.outputs.dcrId
output actionGroupId string = createActionGroup ? actionGroup.outputs.actionGroupId : ''
output workbookId string = deployDashboard ? workbook.outputs.workbookId : ''
output dashboardUrl string = deployDashboard ? 'https://portal.azure.com/#blade/AppInsightsExtension/UsageNotebookBlade/ComponentId/${workbook.outputs.workbookId}' : ''
