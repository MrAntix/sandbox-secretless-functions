using Azure.Identity;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Azure;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Sandbox.Secretless.Functions;

var host = new HostBuilder()
    .ConfigureAppConfiguration((hostingContext, config) =>
    {
        config
            .SetBasePath(Directory.GetCurrentDirectory())
            .AddJsonFile("local.settings.json", optional: true, reloadOnChange: true)
            .AddEnvironmentVariables();
    })
    .ConfigureFunctionsWebApplication()
    .ConfigureLogging((hostingContext, logging) =>
    {
        logging
            .AddConfiguration(hostingContext.Configuration.GetSection("Logging"))
            .AddConsole();
    })
    .ConfigureServices((host, services) =>
    {
        var credential = new DefaultAzureCredential();

        services
            .AddApplicationInsightsTelemetryWorkerService()
            .ConfigureFunctionsApplicationInsights()
            .AddAzureClients(config =>
            {
                config
                    .UseCredential(credential);
            });

        services
            .AddLogging(o => o.AddConsole())
            .AddAppServices(host.Configuration, credential);
    })
    .Build();

host.Run();
