targetScope = 'resourceGroup'

@description('Deployment name')
param deploymentName string

@description('Azure region')
param location string = resourceGroup().location

@description('Use existing Log Analytics')
param useExistingLogAnalytics bool = false

@description('Existing Log Analytics Workspace ID')
param existingLogAnalyticsWorkspaceId string = ''

@description('Log Analytics Workspace name')
param logAnalyticsWorkspaceName string

@description('Log retention in days')
@minValue(30)
@maxValue(730)
param retentionInDays int = 90

@description('Monitor existing VMs')
param monitorExistingVMs bool = false

@description('Selected VM IDs')
param selectedVMIds array = []

@description('Auto-enroll new VMs')
param autoEnrollNewVMs bool = true

@description('Enable CPU alerts')
param enableCPUAlerts bool = true

@description('CPU threshold')
@minValue(50)
@maxValue(100)
param cpuThreshold int = 85

@description('Enable Memory alerts')
param enableMemoryAlerts bool = true

@description('Memory threshold')
@minValue(50)
@maxValue(100)
param memoryThreshold int = 85

@description('Enable Disk alerts')
param enableDiskAlerts bool = true

@description('Disk threshold')
@minValue(50)
@maxValue(100)
param diskThreshold int = 85

@description('Enable Heartbeat alerts')
param enableHeartbeatAlerts bool = true

@description('Create Action Group')
param createActionGroup bool = true

@description('Action Group name')
param actionGroupName string

@description('Email recipients')
param emailRecipients string

@description('Deploy dashboard')
param deployDashboard bool = true

@description('Dashboard name')
param dashboardName string = 'VM Monitoring Dashboard'

@description('Tags by resource')
param tagsByResource object = {}

// Variables
var workspaceName = useExistingLogAnalytics ? split(existingLogAnalyticsWorkspaceId, '/')[8] : logAnalyticsWorkspaceName
var workspaceId = useExistingLogAnalytics ? existingLogAnalyticsWorkspaceId : logAnalyticsWorkspace.id

// Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (!useExistingLogAnalytics) {
  name: logAnalyticsWorkspaceName
  location: location
  tags: contains(tagsByResource, 'Microsoft.OperationalInsights/workspaces') ? tagsByResource['Microsoft.OperationalInsights/workspaces'] : {}
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

// VM Insights Solution
resource vmInsightsSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'VMInsights(${workspaceName})'
  location: location
  plan: {
    name: 'VMInsights(${workspaceName})'
    publisher: 'Microsoft'
    product: 'OMSGallery/VMInsights'
    promotionCode: ''
  }
  properties: {
    workspaceResourceId: workspaceId
  }
  dependsOn: [
    logAnalyticsWorkspace
  ]
}

// Data Collection Rule - Windows
resource dcrWindows 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: 'dcr-${deploymentName}-windows'
  location: location
  tags: contains(tagsByResource, 'Microsoft.Insights/dataCollectionRules') ? tagsByResource['Microsoft.Insights/dataCollectionRules'] : {}
  properties: {
    dataSources: {
      performanceCounters: [
        {
          name: 'perfCounterDataSource'
          samplingFrequencyInSeconds: 60
          streams: [
            'Microsoft-Perf'
          ]
          counterSpecifiers: [
            '\\Processor(_Total)\\% Processor Time'
            '\\Memory\\% Committed Bytes In Use'
            '\\LogicalDisk(_Total)\\% Free Space'
            '\\Network Interface(*)\\Bytes Total/sec'
          ]
        }
      ]
      windowsEventLogs: [
        {
          name: 'eventLogsDataSource'
          streams: [
            'Microsoft-Event'
          ]
          xPathQueries: [
            'System!*[System[(Level=1 or Level=2 or Level=3)]]'
            'Application!*[System[(Level=1 or Level=2 or Level=3)]]'
          ]
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          name: 'la-workspace'
          workspaceResourceId: workspaceId
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-Perf'
          'Microsoft-Event'
        ]
        destinations: [
          'la-workspace'
        ]
      }
    ]
  }
  dependsOn: [
    logAnalyticsWorkspace
  ]
}

// Data Collection Rule - Linux
resource dcrLinux 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: 'dcr-${deploymentName}-linux'
  location: location
  tags: contains(tagsByResource, 'Microsoft.Insights/dataCollectionRules') ? tagsByResource['Microsoft.Insights/dataCollectionRules'] : {}
  properties: {
    dataSources: {
      performanceCounters: [
        {
          name: 'perfCounterDataSource'
          samplingFrequencyInSeconds: 60
          streams: [
            'Microsoft-Perf'
          ]
          counterSpecifiers: [
            'Processor(*)\\% Processor Time'
            'Memory(*)\\% Used Memory'
            'Logical Disk(*)\\% Used Space'
            'Network(*)\\Total Bytes Transmitted'
          ]
        }
      ]
      syslog: [
        {
          name: 'syslogDataSource'
          streams: [
            'Microsoft-Syslog'
          ]
          facilityNames: [
            'auth'
            'authpriv'
            'cron'
            'daemon'
            'kern'
            'syslog'
          ]
          logLevels: [
            'Error'
            'Critical'
            'Alert'
            'Emergency'
          ]
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          name: 'la-workspace'
          workspaceResourceId: workspaceId
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-Perf'
          'Microsoft-Syslog'
        ]
        destinations: [
          'la-workspace'
        ]
      }
    ]
  }
  dependsOn: [
    logAnalyticsWorkspace
  ]
}

// Action Group
resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = if (createActionGroup) {
  name: actionGroupName
  location: 'global'
  tags: contains(tagsByResource, 'Microsoft.Insights/actionGroups') ? tagsByResource['Microsoft.Insights/actionGroups'] : {}
  properties: {
    groupShortName: take(actionGroupName, 12)
    enabled: true
    emailReceivers: [for email in split(emailRecipients, ';'): {
      name: 'email-${uniqueString(email)}'
      emailAddress: trim(email)
      useCommonAlertSchema: true
    }]
  }
}

// CPU Alert
resource cpuAlert 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = if (enableCPUAlerts) {
  name: 'alert-${deploymentName}-cpu'
  location: location
  tags: contains(tagsByResource, 'Microsoft.Insights/scheduledQueryRules') ? tagsByResource['Microsoft.Insights/scheduledQueryRules'] : {}
  properties: {
    displayName: 'High CPU Usage - ${deploymentName}'
    description: 'Alert when CPU usage exceeds ${cpuThreshold}%'
    severity: 2
    enabled: true
    evaluationFrequency: 'PT5M'
    scopes: [
      workspaceId
    ]
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: 'Perf | where ObjectName == "Processor" and CounterName == "% Processor Time" | where CounterValue > ${cpuThreshold} | summarize AggregatedValue = avg(CounterValue) by Computer, bin(TimeGenerated, 5m)'
          timeAggregation: 'Average'
          dimensions: []
          operator: 'GreaterThan'
          threshold: cpuThreshold
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: {
      actionGroups: createActionGroup ? [actionGroup.id] : []
    }
  }
  dependsOn: [
    logAnalyticsWorkspace
    vmInsightsSolution
  ]
}

// Memory Alert  
resource memoryAlert 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = if (enableMemoryAlerts) {
  name: 'alert-${deploymentName}-memory'
  location: location
  tags: contains(tagsByResource, 'Microsoft.Insights/scheduledQueryRules') ? tagsByResource['Microsoft.Insights/scheduledQueryRules'] : {}
  properties: {
    displayName: 'High Memory Usage - ${deploymentName}'
    description: 'Alert when Memory usage exceeds ${memoryThreshold}%'
    severity: 2
    enabled: true
    evaluationFrequency: 'PT5M'
    scopes: [
      workspaceId
    ]
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: 'Perf | where ObjectName == "Memory" and CounterName == "% Committed Bytes In Use" | where CounterValue > ${memoryThreshold} | summarize AggregatedValue = avg(CounterValue) by Computer, bin(TimeGenerated, 5m)'
          timeAggregation: 'Average'
          dimensions: []
          operator: 'GreaterThan'
          threshold: memoryThreshold
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: {
      actionGroups: createActionGroup ? [actionGroup.id] : []
    }
  }
  dependsOn: [
    logAnalyticsWorkspace
    vmInsightsSolution
  ]
}

// Disk Alert
resource diskAlert 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = if (enableDiskAlerts) {
  name: 'alert-${deploymentName}-disk'
  location: location
  tags: contains(tagsByResource, 'Microsoft.Insights/scheduledQueryRules') ? tagsByResource['Microsoft.Insights/scheduledQueryRules'] : {}
  properties: {
    displayName: 'Low Disk Space - ${deploymentName}'
    description: 'Alert when Disk free space is below ${100 - diskThreshold}%'
    severity: 2
    enabled: true
    evaluationFrequency: 'PT15M'
    scopes: [
      workspaceId
    ]
    windowSize: 'PT15M'
    criteria: {
      allOf: [
        {
          query: 'Perf | where ObjectName == "LogicalDisk" and CounterName == "% Free Space" | where CounterValue < ${100 - diskThreshold} | summarize AggregatedValue = avg(CounterValue) by Computer, InstanceName, bin(TimeGenerated, 15m)'
          timeAggregation: 'Average'
          dimensions: []
          operator: 'LessThan'
          threshold: 100 - diskThreshold
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: {
      actionGroups: createActionGroup ? [actionGroup.id] : []
    }
  }
  dependsOn: [
    logAnalyticsWorkspace
    vmInsightsSolution
  ]
}

// Heartbeat Alert
resource heartbeatAlert 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = if (enableHeartbeatAlerts) {
  name: 'alert-${deploymentName}-heartbeat'
  location: location
  tags: contains(tagsByResource, 'Microsoft.Insights/scheduledQueryRules') ? tagsByResource['Microsoft.Insights/scheduledQueryRules'] : {}
  properties: {
    displayName: 'VM Heartbeat Missing - ${deploymentName}'
    description: 'Alert when VM stops sending heartbeat'
    severity: 1
    enabled: true
    evaluationFrequency: 'PT5M'
    scopes: [
      workspaceId
    ]
    windowSize: 'PT15M'
    criteria: {
      allOf: [
        {
          query: 'Heartbeat | summarize LastHeartbeat = max(TimeGenerated) by Computer | where LastHeartbeat < ago(10m)'
          timeAggregation: 'Count'
          dimensions: []
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: {
      actionGroups: createActionGroup ? [actionGroup.id] : []
    }
  }
  dependsOn: [
    logAnalyticsWorkspace
    vmInsightsSolution
  ]
}

// Outputs
output resourceGroupName string = resourceGroup().name
output logAnalyticsWorkspaceId string = workspaceId
output logAnalyticsWorkspaceName string = workspaceName
output dcrWindowsId string = dcrWindows.id
output dcrLinuxId string = dcrLinux.id
output actionGroupId string = createActionGroup ? actionGroup.id : ''
