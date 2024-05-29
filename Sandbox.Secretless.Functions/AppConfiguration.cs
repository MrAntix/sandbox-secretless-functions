using Azure.Core;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Sandbox.Secretless.Functions.Azure;
using Sandbox.Secretless.Functions.Incoming;

namespace Sandbox.Secretless.Functions
{
    public static class AppConfiguration
    {
        public static IServiceCollection AddAppServices(
            this IServiceCollection services,
            IConfiguration settingsSection,
            TokenCredential credential
        )
        {
            return services
                .AddAzureServices(settingsSection.GetSection("Azure").Get<AzureSettings>()!, credential)
                .AddIncomingServices(settingsSection.GetSection("Incoming").Get<IncomingSettings>()!);
        }
    }
}