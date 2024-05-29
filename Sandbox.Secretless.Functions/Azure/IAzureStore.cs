namespace Sandbox.Secretless.Functions.Azure;

public interface IAzureStore
{
    public Task PutAsync(string id, string message);
}
