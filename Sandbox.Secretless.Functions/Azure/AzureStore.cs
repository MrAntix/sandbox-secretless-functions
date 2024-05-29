
using Azure.Data.Tables;
using Microsoft.Extensions.Logging;

namespace Sandbox.Secretless.Functions.Azure;

public class AzureStore(
    ILogger<AzureStore> logger,
    TableClient client
    ) : IAzureStore
{
    public async Task PutAsync(string id, string message)
    {
        logger.LogInformation("Process message {Id}", id);

        var entity = new TableEntity(id, message);
        try
        {
            await client.UpsertEntityAsync(entity);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error processing message {Id}", id);
            throw;
        }
    }
}
