using Azure.Data.Tables;
using Microsoft.Extensions.Logging;

namespace Sandbox.Secretless.Functions.Azure;

public sealed class AzureStoreProvider(
    ILogger<AzureStore> logger,
    Func<string, TableClient> getTableClient
    ) : IAzureStoreProvider
{
    public IAzureStore Get(string tableName)
        => new AzureStore(
            logger,
            getTableClient(tableName)
        );
}
