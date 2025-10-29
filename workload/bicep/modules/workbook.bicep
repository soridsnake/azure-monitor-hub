@description('Workbook display name')
param workbookName string

@description('Azure region')
param location string

@description('Log Analytics Workspace Resource ID')
param workspaceResourceId string

@description('Resource tags')
param tags object = {}

var workbookId = guid(workbookName, resourceGroup().id)

resource workbook 'Microsoft.Insights/workbooks@2023-06-01' = {
  name: workbookId
  location: location
  tags: tags
  kind: 'shared'
  properties: {
    displayName: workbookName
    serializedData: '{"version":"Notebook/1.0","items":[{"type":1,"content":{"json":"## VM Monitoring Dashboard\\n---\\nMonitoring dashboard for Azure Virtual Machines."},"name":"text-header"}]}'
    version: '1.0'
    sourceId: workspaceResourceId
    category: 'Azure Monitor'
  }
}

output workbookId string = workbook.id
output workbookName string = workbook.name
