namespace Pipelines.Runtime.Helpers;

public static class FunctionsHelper
{
    public static string GetEnvironment()
    {
        var environment = Environment.GetEnvironmentVariable("AZURE_FUNCTIONS_ENVIRONMENT");
        if (environment is null)
        {
            throw new Exception("Environment variable (AZURE_FUNCTIONS_ENVIRONMENT) is not set.");
        }

        return environment;
    }
}