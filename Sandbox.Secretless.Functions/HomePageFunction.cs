using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

namespace Sandbox.Secretless.Functions;

public sealed class HomePageFunction
{
    [Function(nameof(HomePageFunction))]
    public HttpResponseData Run(
        [HttpTrigger(
            AuthorizationLevel.Anonymous,
            "get", Route = "home")] HttpRequestData req,
        FunctionContext executionContext)
    {
        var logger = executionContext.GetLogger("HomePageFunction");
        logger.LogInformation("C# HTTP trigger function processed a request.");

        var response = req.CreateResponse(System.Net.HttpStatusCode.OK);
        response.WriteString("Welcome to the home page!");

        return response;
    }
}
