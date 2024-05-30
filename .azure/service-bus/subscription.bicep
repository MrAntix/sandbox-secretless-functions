param namespaceName string
param topicName string
@minLength(3)
@maxLength(40)
param name string
param filter Filter?
param variants array = []

type Filter = {
  name: string
  properties: object
}

resource namespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' existing = {
  name: namespaceName
}
resource topic 'Microsoft.ServiceBus/namespaces/topics@2022-10-01-preview' existing = {
  parent: namespace
  name: topicName
}

resource subscription 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2022-10-01-preview' = {
  parent: topic
  name: name
}

resource topicVariants 'Microsoft.ServiceBus/namespaces/topics@2022-10-01-preview' existing = [
  for variant in variants: {
    parent: namespace
    name: '${topicName}-${variant}'
  }
]

resource subscriptionVariants 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2022-10-01-preview' = [
  for (variant, i) in variants: if (!empty(variant)) {
    parent: topicVariants[i]
    name: name
  }
]

resource subscriptionFilter 'Microsoft.ServiceBus/namespaces/topics/subscriptions/rules@2022-10-01-preview' = if (!empty(filter)) {
  parent: subscription
  name: filter!.name
  properties: {
    filterType: 'CorrelationFilter'
    correlationFilter: {
      properties: filter!.properties
    }
  }
}

resource subscriptionFilterVariants 'Microsoft.ServiceBus/namespaces/topics/subscriptions/rules@2022-10-01-preview' = [
  for (variant, i) in variants: if (!empty(variant) && !empty(filter)) {
    parent: subscriptionVariants[i]
    name: filter!.name
    properties: {
      filterType: 'CorrelationFilter'
      correlationFilter: {
        properties: filter!.properties
      }
    }
  }
]

output id string = subscription.id
