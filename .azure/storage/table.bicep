param storageAccountName string
@minLength(3)
@maxLength(40)
param name string
param variants array = []

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-04-01' existing = {
  name: storageAccountName
}

resource tableService 'Microsoft.Storage/storageAccounts/tableServices@2023-04-01' existing = {
  parent: storageAccount
  name: 'default'
}

resource table 'Microsoft.Storage/storageAccounts/tableServices/tables@2023-04-01' = {
  parent: tableService
  name: name
}

resource tableVariants 'Microsoft.Storage/storageAccounts/tableServices/tables@2023-04-01' = [
  for variant in variants: if (!empty(variant)) {
    parent: tableService
    name: '${name}${variant}'
  }
]

output id string = table.id
