var ROLES = {
  ACCOUNT_CONTRIBUTOR: '17d1049b-9a84-46fb-8f53-869881c3d3ab'
  BLOB_DATA_CONTRIBUTOR: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
  TABLE_DATA_CONTRIBUTOR: '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3'
}

param storageAccountName string
@allowed([
  'ACCOUNT_CONTRIBUTOR'
  'BLOB_DATA_CONTRIBUTOR'
  'TABLE_DATA_CONTRIBUTOR'
])
param roleName string
param principalId string

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-04-01' existing = {
  name: storageAccountName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccountName, roleName, principalId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', ROLES[roleName])
    principalId: principalId
  }
}

output id string = roleAssignment.id
