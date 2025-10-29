targetScope = 'subscription'

@description('Policy name')
param policyName string

@description('Data Collection Rule ID')
param dcrId string

@description('Policy assignment name')
param assignmentName string

@description('Location for policy assignment')
param location string

// Built-in policy definition for installing Azure Monitor Agent on Windows VMs
var windowsPolicyDefinitionId = '/providers/Microsoft.Authorization/policyDefinitions/ca817e41-e85a-4783-bc7f-dc532d36235e'

// Built-in policy definition for installing Azure Monitor Agent on Linux VMs
var linuxPolicyDefinitionId = '/providers/Microsoft.Authorization/policyDefinitions/a4034bc6-ae50-406d-bf76-50f4ee5a7811'

// Built-in policy definition for associating VMs with DCR
var dcrAssociationPolicyDefinitionId = '/providers/Microsoft.Authorization/policyDefinitions/2ea82cdd-f2e8-4500-af75-67a2e084ca74'

// Policy Initiative (combines all three policies)
resource policySetDefinition 'Microsoft.Authorization/policySetDefinitions@2023-04-01' = {
  name: policyName
  properties: {
    displayName: 'Deploy Azure Monitor Agent and associate with DCR'
    description: 'Automatically deploy Azure Monitor Agent to VMs and associate them with the specified Data Collection Rule'
    policyType: 'Custom'
    metadata: {
      category: 'Monitoring'
    }
    parameters: {
      dcrResourceId: {
        type: 'String'
        metadata: {
          displayName: 'Data Collection Rule Resource ID'
          description: 'Resource ID of the Data Collection Rule to associate with VMs'
        }
      }
      effect: {
        type: 'String'
        defaultValue: 'DeployIfNotExists'
        allowedValues: [
          'DeployIfNotExists'
          'Disabled'
        ]
        metadata: {
          displayName: 'Effect'
          description: 'Enable or disable the execution of the policy'
        }
      }
    }
    policyDefinitions: [
      {
        policyDefinitionId: windowsPolicyDefinitionId
        parameters: {
          effect: {
            value: '[parameters(\'effect\')]'
          }
        }
        policyDefinitionReferenceId: 'DeployAMAWindows'
      }
      {
        policyDefinitionId: linuxPolicyDefinitionId
        parameters: {
          effect: {
            value: '[parameters(\'effect\')]'
          }
        }
        policyDefinitionReferenceId: 'DeployAMALinux'
      }
      {
        policyDefinitionId: dcrAssociationPolicyDefinitionId
        parameters: {
          effect: {
            value: '[parameters(\'effect\')]'
          }
          dcrResourceId: {
            value: '[parameters(\'dcrResourceId\')]'
          }
        }
        policyDefinitionReferenceId: 'AssociateDCR'
      }
    ]
  }
}

// Assign the policy initiative to the subscription
resource policyAssignment 'Microsoft.Authorization/policyAssignments@2023-04-01' = {
  name: assignmentName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'Auto-enroll VMs to Azure Monitor'
    description: 'Automatically installs Azure Monitor Agent and associates VMs with Data Collection Rule'
    policyDefinitionId: policySetDefinition.id
    parameters: {
      dcrResourceId: {
        value: dcrId
      }
      effect: {
        value: 'DeployIfNotExists'
      }
    }
    enforcementMode: 'Default'
  }
}

// Role assignment for the policy's managed identity
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(policyAssignment.id, 'Contributor')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor role
    principalId: policyAssignment.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

output policySetDefinitionId string = policySetDefinition.id
output policyAssignmentId string = policyAssignment.id
