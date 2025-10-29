@description('Azure region')
param location string

@description('Log Analytics Workspace Resource ID')
param workspaceResourceId string

@description('Action Group ID')
param actionGroupId string

@description('Enable CPU alerts')
param enableCPUAlerts bool

@description('CPU threshold')
param cpuThreshold int

@description('Enable Memory alerts')
param enableMemoryAlerts bool

@description('Memory threshold')
param memoryThreshold int

@description('Enable Disk alerts')
param enableDiskAlerts bool

@description('Disk threshold')
param diskThreshold int

@description('Enable Heartbeat alerts')
param enableHeartbeatAlerts bool

@description('Alert name prefix')
param alertNamePrefix string

@description('Resource tags')
param tags object = {}

// CPU Alert
resource cpuAlert 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = if (enableCPUAlerts) {
  name: 'alert-${alertNamePrefix}-high-cpu'
  location: location
  tags: tags
  properties: {
    displayName: 'High CPU Usage Alert'
    description: 'Alert when CPU usage exceeds ${cpuThreshold}%'
    severity: 2
    enabled: true
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    scopes: [
      workspaceResourceId
    ]
    criteria: {
      allOf: [
        {
          query: 'Perf | where ObjectName == "Processor" and CounterName == "% Processor Time" | where InstanceName == "_Total" | summarize AggregatedValue = avg(CounterValue) by Computer, bin(TimeGenerated, 5m) | where AggregatedValue > ${cpuThreshold}'
          timeAggregation: 'Average'
          metricMeasureColumn: 'AggregatedValue'
          operator: 'GreaterThan'
          threshold: cpuThreshold
          failingPeriods: {
            numberOfEvaluationPeriods: 2
            minFailingPeriodsToAlert: 2
          }
        }
      ]
    }
    actions: {
      actionGroups: [
        actionGroupId
      ]
    }
  }
}

// Memory Alert
resource memoryAlert 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = if (enableMemoryAlerts) {
  name: 'alert-${alertNamePrefix}-high-memory'
  location: location
  tags: tags
  properties: {
    displayName: 'High Memory Usage Alert'
    description: 'Alert when Memory usage exceeds ${memoryThreshold}%'
    severity: 2
    enabled: true
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    scopes: [
      workspaceResourceId
    ]
    criteria: {
      allOf: [
        {
          query: 'Perf | where ObjectName == "Memory" and CounterName == "% Committed Bytes In Use" | summarize AggregatedValue = avg(CounterValue) by Computer, bin(TimeGenerated, 5m) | where AggregatedValue > ${memoryThreshold}'
          timeAggregation: 'Average'
          metricMeasureColumn: 'AggregatedValue'
          operator: 'GreaterThan'
          threshold: memoryThreshold
          failingPeriods: {
            numberOfEvaluationPeriods: 2
            minFailingPeriodsToAlert: 2
          }
        }
      ]
    }
    actions: {
      actionGroups: [
        actionGroupId
      ]
    }
  }
}

// Disk Alert
resource diskAlert 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = if (enableDiskAlerts) {
  name: 'alert-${alertNamePrefix}-low-disk'
  location: location
  tags: tags
  properties: {
    displayName: 'Low Disk Space Alert'
    description: 'Alert when Disk usage exceeds ${diskThreshold}%'
    severity: 2
    enabled: true
    evaluationFrequency: 'PT15M'
    windowSize: 'PT30M'
    scopes: [
      workspaceResourceId
    ]
    criteria: {
      allOf: [
        {
          query: 'Perf | where ObjectName == "LogicalDisk" and CounterName == "% Free Space" | where InstanceName != "_Total" | summarize AggregatedValue = avg(CounterValue) by Computer, InstanceName, bin(TimeGenerated, 15m) | where AggregatedValue < ${100 - diskThreshold}'
          timeAggregation: 'Average'
          metricMeasureColumn: 'AggregatedValue'
          operator: 'LessThan'
          threshold: 100 - diskThreshold
          failingPeriods: {
            numberOfEvaluationPeriods: 2
            minFailingPeriodsToAlert: 2
          }
        }
      ]
    }
    actions: {
      actionGroups: [
        actionGroupId
      ]
    }
  }
}

// Heartbeat Alert
resource heartbeatAlert 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = if (enableHeartbeatAlerts) {
  name: 'alert-${alertNamePrefix}-vm-offline'
  location: location
  tags: tags
  properties: {
    displayName: 'VM Offline Alert'
    description: 'Alert when VM stops sending heartbeat'
    severity: 1
    enabled: true
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    scopes: [
      workspaceResourceId
    ]
    criteria: {
      allOf: [
        {
          query: 'Heartbeat | summarize LastHeartbeat = max(TimeGenerated) by Computer | where LastHeartbeat < ago(10m)'
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 2
            minFailingPeriodsToAlert: 2
          }
        }
      ]
    }
    actions: {
      actionGroups: [
        actionGroupId
      ]
    }
  }
}

output cpuAlertId string = enableCPUAlerts ? cpuAlert.id : ''
output memoryAlertId string = enableMemoryAlerts ? memoryAlert.id : ''
output diskAlertId string = enableDiskAlerts ? diskAlert.id : ''
output heartbeatAlertId string = enableHeartbeatAlerts ? heartbeatAlert.id : ''
