@minLength(4)
param name string

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
])
param skuName string = 'Standard_LRS'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-04-01' = {
  name: name
  location: resourceGroup().location
  sku: {
    name: skuName
  }
  kind: 'StorageV2'
}

output id string = storageAccount.id
output blob string = storageAccount.properties.primaryEndpoints.blob
