using Azure.Core;
using Azure.Data.Tables;
using Microsoft.Extensions.DependencyInjection;

namespace Sandbox.Secretless.Functions.Azure;

public static class AzureConfiguration
{
    public static IServiceCollection AddAzureServices(
        this IServiceCollection services,
        AzureSettings settings, TokenCredential credential
    )
    {
        ArgumentNullException.ThrowIfNull(settings);
        ArgumentNullException.ThrowIfNull(credential);

        services.AddSingleton<Func<string, TableClient>>(
            tableName => new TableClient(
                new Uri(settings.TableEndpoint),
                tableName,
                credential
                )
            );
        services.AddSingleton<IAzureStoreProvider, AzureStoreProvider>();
        services.AddTransient<IAzureStore, AzureStore>();

        return services;
    }
}
