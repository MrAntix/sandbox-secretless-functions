using Microsoft.Extensions.Logging;
using Sandbox.Secretless.Functions.Azure;

namespace Sandbox.Secretless.Functions.Incoming;

public class IncomingService(
    ILogger<IncomingService> logger,
    IncomingSettings settings,
    IAzureStoreProvider azureStoreProvider
) : IIncomingService
{
    readonly IAzureStore _store = azureStoreProvider
        .Get(settings.StoreName);

    public async Task PutAsync(string id, string message)
    {
        logger.LogInformation("Process message {Id}", id);

        await _store.PutAsync(id, message);
    }
}
