param namespaceName string
param topicName string
@minLength(3)
@maxLength(40)
param name string
param filter object = {}
param variants array = []

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

resource topicVariants 'Microsoft.ServiceBus/namespaces/topics@2022-10-01-preview' = [
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
  name: '${name}Filter'
  properties: {
    filterType: 'CorrelationFilter'
    correlationFilter: {
      properties: filter
    }
  }
}

resource subscriptionFilterVariants 'Microsoft.ServiceBus/namespaces/topics/subscriptions/rules@2022-10-01-preview' = [
  for (variant, i) in variants: if (!empty(variant) && !empty(filter)) {
    parent: subscriptionVariants[i]
    name: '${name}Filter-${variant}'
    properties: {
      filterType: 'CorrelationFilter'
      correlationFilter: {
        properties: filter
      }
    }
  }
]

output id string = subscription.id
