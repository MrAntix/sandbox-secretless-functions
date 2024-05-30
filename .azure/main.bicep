@minLength(4)
param prefix string
@minLength(4)
param groupId string
param buildId string

var prefixSafe = toLower(replace(prefix, '-', ''))

var devs = ['aj']
var variants = empty(buildId) ? devs : [buildId, ...devs]

var storageAccountName = '${prefixSafe}store'
output storageAccountName string = storageAccountName

var serviceBusNamespaceName = '${prefix}-sbns'
output serviceBusNamespaceName string = serviceBusNamespaceName

var incomingTopicName = '${prefix}-sbt-incoming'
var incomingRegistrationSubscriptionName = '${prefix}-sbs-registration'
var servicePlanName = '${prefix}-plan'
var logAnalyticsWorkspaceName = '${prefix}-logs'
var appInsightsName = '${prefix}-insights'
var appName = '${prefix}-app'
var incomingStoreName = 'incoming'
var isLinux = false

// Storage Account --------------------------------------------------------------------------------
module storageAccount 'storage/account.bicep' = {
  name: storageAccountName
  params: {
    name: storageAccountName
    skuName: 'Standard_LRS'
  }
}

module storageBlobDataContributer 'storage/add-role.bicep' = {
  name: guid(storageAccountName, groupId, 'BLOB_DATA_CONTRIBUTOR')
  params: {
    storageAccountName: storageAccountName
    roleName: 'BLOB_DATA_CONTRIBUTOR'
    principalId: groupId
  }
  dependsOn: [
    storageAccount
  ]
}

module storageTableDataContributer 'storage/add-role.bicep' = {
  name: guid(storageAccountName, groupId, 'TABLE_DATA_CONTRIBUTOR')
  params: {
    storageAccountName: storageAccountName
    roleName: 'TABLE_DATA_CONTRIBUTOR'
    principalId: groupId
  }
  dependsOn: [
    storageAccount
  ]
}

module incomingStore 'storage/table.bicep' = {
  name: incomingStoreName
  params: {
    storageAccountName: storageAccountName
    name: incomingStoreName
    variants: variants
  }
  dependsOn: [
    storageAccount
  ]
}

// Service Bus ------------------------------------------------------------------------------------
module serviceBusNamespace 'service-bus/namespace.bicep' = {
  name: serviceBusNamespaceName
  params: {
    name: serviceBusNamespaceName
  }
}

module serviceBusNamespaceOwner 'service-bus/add-role.bicep' = {
  name: guid(serviceBusNamespaceName, groupId, 'OWNER')
  params: {
    namespaceName: serviceBusNamespaceName
    roleName: 'OWNER'
    principalId: groupId
  }
  dependsOn: [
    serviceBusNamespace
  ]
}

module incomingTopic 'service-bus/topic.bicep' = {
  name: incomingTopicName
  params: {
    namespaceName: serviceBusNamespaceName
    name: incomingTopicName
    variants: variants
  }
  dependsOn: [
    serviceBusNamespace
  ]
}

module incomingSubscription 'service-bus/subscription.bicep' = {
  name: incomingRegistrationSubscriptionName
  params: {
    namespaceName: serviceBusNamespaceName
    topicName: incomingTopicName
    name: incomingRegistrationSubscriptionName
    variants: variants
    filter: {
      name: 'registrationEvent'
      properties: {
        eventType: 'registration'
      }
    }
  }
  dependsOn: [
    incomingTopic
  ]
}

// App Insights ----------------------------------------------------------------------------------
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = {
  name: logAnalyticsWorkspaceName
  location: resourceGroup().location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: resourceGroup().location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
    RetentionInDays: 30
  }
}

// Functions App ----------------------------------------------------------------------------------
var APP_ROLES = {
  CONTRIBUTER: '641177b8-a67a-45b9-a033-47bc880bb21e'
}

resource servicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: servicePlanName
  location: resourceGroup().location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {
    reserved: isLinux
  }
}

resource app 'Microsoft.Web/sites@2023-12-01' = {
  name: appName
  location: resourceGroup().location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: servicePlan.id
    reserved: isLinux
    siteConfig: {
      netFrameworkVersion: isLinux ? null : 'v8.0'
      linuxFxVersion: isLinux ? 'DOTNET-ISOLATED|8.0' : null
      use32BitWorkerProcess: false
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'AzureWebJobsStorage__accountName'
          value: storageAccount.name
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet-isolated'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'ServiceBus__Connection__fullyQualifiedNamespace'
          value: '${serviceBusNamespace.name}.servicebus.windows.net'
        }
        {
          name: 'Incoming__Topic'
          value: incomingTopicName
        }
        {
          name: 'Incoming__Subscription__Registration'
          value: incomingRegistrationSubscriptionName
        }
        {
          name: 'Azure__TableEndpoint'
          value: 'https://${storageAccount.name}.table.${environment().suffixes.storage}/'
        }
        {
          name: 'Incoming__StoreName'
          value: incomingStoreName
        }
      ]
    }
  }
  dependsOn: [
    storageAccount
    serviceBusNamespace
    incomingTopic
    incomingStore
  ]
}

resource appContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(groupId, app.id, APP_ROLES.CONTRIBUTER)
  scope: app
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', APP_ROLES.CONTRIBUTER)
    principalId: groupId
  }
}

output appPrincipalId string = app.identity.principalId
output appName string = app.name
output appHostname string = app.properties.defaultHostName
