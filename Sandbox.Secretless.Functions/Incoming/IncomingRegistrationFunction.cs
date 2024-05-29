using Azure.Messaging.ServiceBus;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace Sandbox.Secretless.Functions.Incoming;

public sealed class IncomingRegistrationFunction(
    ILogger<IncomingRegistrationFunction> logger,
    IIncomingService incomingService
    )
{
    [Function(nameof(IncomingRegistrationFunction))]
    public async Task Run(
        [ServiceBusTrigger(
            topicName : "%Incoming:Topic%",
            subscriptionName : "%Incoming:Subscription:Registration%",
            Connection = "ServiceBus:Connection",
            AutoCompleteMessages = false
        )]
        ServiceBusReceivedMessage message,
        ServiceBusMessageActions messageActions)
    {
        logger.LogInformation("Message ID: {MessageId}", message.MessageId);
        logger.LogInformation("Message Body: {Body}", message.Body);
        logger.LogInformation("Message Content-Type: {ContentType}", message.ContentType);

        await incomingService.PutAsync(message.MessageId, message.Body.ToString());

        await messageActions.CompleteMessageAsync(message);
    }
}
