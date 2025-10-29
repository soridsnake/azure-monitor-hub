@description('VM Name')
param vmName string

@description('Location')
param location string

@description('Data Collection Rule ID')
param dcrId string

// Get VM reference
resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' existing = {
  name: vmName
}

// Deploy Azure Monitor Agent extension
resource amaExtension 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = {
  parent: vm
  name: 'AzureMonitorAgent'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorWindowsAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
  }
}

// Associate with DCR
resource dcrAssociation 'Microsoft.Insights/dataCollectionRuleAssociations@2022-06-01' = {
  name: 'dcra-${uniqueString(vm.id, dcrId)}'
  scope: vm
  properties: {
    dataCollectionRuleId: dcrId
  }
  dependsOn: [
    amaExtension
  ]
}

output associationId string = dcrAssociation.id
