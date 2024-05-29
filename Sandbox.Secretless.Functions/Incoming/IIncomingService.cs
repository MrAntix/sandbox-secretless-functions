namespace Sandbox.Secretless.Functions.Incoming;

public interface IIncomingService
{
    Task PutAsync(string id, string message);
}
