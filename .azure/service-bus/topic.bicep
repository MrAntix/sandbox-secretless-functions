param namespaceName string
@minLength(3)
@maxLength(40)
param name string
param variants array = []

resource namespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' existing = {
  name: namespaceName
}

resource topic 'Microsoft.ServiceBus/namespaces/topics@2022-10-01-preview' = {
  parent: namespace
  name: name
}

resource topicVariants 'Microsoft.ServiceBus/namespaces/topics@2022-10-01-preview' = [
  for variant in variants: if (!empty(variant)) {
    parent: namespace
    name: '${name}-${variant}'
  }
]

output id string = topic.id
