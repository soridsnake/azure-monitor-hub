@description('Action Group name')
param actionGroupName string

@description('Location (global for action groups)')
param location string = 'global'

@description('Email recipients (semicolon separated)')
param emailRecipients string

@description('Resource tags')
param tags object = {}

var emailArray = split(emailRecipients, ';')

resource actionGroup 'Microsoft.Insights/actionGroups@2023-09-01' = {
  name: actionGroupName
  location: location
  tags: tags
  properties: {
    groupShortName: take(actionGroupName, 12)
    enabled: true
    emailReceivers: [for (email, i) in emailArray: {
      name: 'email-${i}'
      emailAddress: trim(email)
      useCommonAlertSchema: true
    }]
  }
}

output actionGroupId string = actionGroup.id
output actionGroupName string = actionGroup.name
