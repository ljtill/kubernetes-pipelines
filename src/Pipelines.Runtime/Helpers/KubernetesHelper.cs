using Pipelines.Runtime.Clients;
using Pipelines.Runtime.Models;

namespace Pipelines.Runtime.Helpers;

public static class KubernetesHelper
{
    public static k8s.KubernetesClientConfiguration GetClientConfig()
    {
        switch (FunctionsHelper.GetEnvironment())
        {
            case "Development":
                var filePath = GetClusterFilePath();
                // TODO(ljtill): Remove context setting (azure)
                // TODO(ljtill): Wire in ENV VAR for context value
                // NOTE: This uses the default context in the kubeconfig file
                return k8s.KubernetesClientConfiguration.BuildConfigFromConfigFile(filePath, "azure");
            case "Production":
                return k8s.KubernetesClientConfiguration.InClusterConfig();
            default:
                throw new Exception("Unsupported Azure Functions environment");
        }
    }

    private static string GetClusterFilePath()
    {
        var filePath = Environment.GetEnvironmentVariable("KUBE_CONFIG_PATH");
        if (filePath is null)
        {
            throw new Exception("Environment variable (KUBE_CONFIG_PATH) is unset");
        }

        return filePath;
    }

    public static string GetResponseMessage(string message)
    {
        return JsonSerializer.Deserialize<OperationResult>(message)?.Message;
    }
}
