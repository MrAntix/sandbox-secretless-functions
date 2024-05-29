namespace Sandbox.Secretless.Functions.Azure;

public interface IAzureStoreProvider
{
    public IAzureStore Get(string tableName);
}
