var ROLES = {
  OWNER: '090c5cfd-751d-490a-894a-3ce6f1109419'
  SENDER: '69a216fc-b8fb-44d8-bc22-1f3c2cd27a39'
  RECEIVER: '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0'
}

param namespaceName string
@allowed([
  'OWNER'
  'SENDER'
  'RECEIVER'
])
param roleName string
param principalId string

resource namespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' existing = {
  name: namespaceName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(namespaceName, roleName, principalId)
  scope: namespace
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', ROLES[roleName])
    principalId: principalId
  }
}

output id string = roleAssignment.id
