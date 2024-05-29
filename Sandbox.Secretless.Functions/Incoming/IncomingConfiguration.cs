using Microsoft.Extensions.DependencyInjection;

namespace Sandbox.Secretless.Functions.Incoming;

public static class IncomingConfiguration
{
    public static IServiceCollection AddIncomingServices(
        this IServiceCollection services,
        IncomingSettings settings
    )
    {
        ArgumentNullException.ThrowIfNull(settings);

        services.AddSingleton(settings);
        services.AddTransient<IIncomingService, IncomingService>();

        return services;
    }
}