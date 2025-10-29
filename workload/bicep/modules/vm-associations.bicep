@description('Array of VM Resource IDs')
param vmIds array

@description('Data Collection Rule ID')
param dcrId string

// Parse VM details from resource IDs
var vmDetails = [for vmId in vmIds: {
  subscriptionId: split(vmId, '/')[2]
  resourceGroup: split(vmId, '/')[4]
  name: split(vmId, '/')[8]
  id: vmId
}]

// Deploy Azure Monitor Agent using deployment script approach
module vmAgentDeployment 'vm-agent-single.bicep' = [for (vm, i) in vmDetails: {
  name: 'deploy-agent-${vm.name}'
  scope: resourceGroup(vm.resourceGroup)
  params: {
    vmName: vm.name
    location: resourceGroup().location
    dcrId: dcrId
  }
}]

output associationIds array = [for (vm, i) in vmDetails: vmAgentDeployment[i].outputs.associationId]
