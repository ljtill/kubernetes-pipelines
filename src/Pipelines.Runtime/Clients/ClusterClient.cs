using Pipelines.Runtime.Loggers;
using Pipelines.Runtime.Models;
using Pipelines.Runtime.Helpers;
using Pipelines.Runtime.Services;

namespace Pipelines.Runtime.Clients;

public class ClusterClient
{
    private readonly ApplicationProperties _appProperties;
    private readonly UserConfigOptions _userConfigOptions;
    private readonly Kubernetes _kubernetes;
    private readonly ClusterService _clusterService;
    private readonly TaskLogger _taskLogger;

    public ClusterClient(IReadOnlyDictionary<string, object> appProperties, BinaryData configData, TaskLogger taskLogger)
    {
        _appProperties = MessageHelper.ParseApplicationProperties(appProperties);
        _userConfigOptions = MessageHelper.ParseConfigurationOptions(configData);

        var config = KubernetesHelper.GetClientConfig();
        _kubernetes = new Kubernetes(config);

        _clusterService = new ClusterService(_kubernetes, _taskLogger);

        _taskLogger = taskLogger;
    }

    public async Task CreateNamespaceIfNotExistsAsync()
    {
        // Check if namespace already exists within the cluster
        if (await _clusterService.ValidateNamespaceByNameIfExistsAsync(_userConfigOptions.ClusterNamespace))
        {
            // Skip creation as namespace already exists
            return;
        }

        try
        {
            // Create namespace
            var @namespace = _clusterService.NewNamespace(_userConfigOptions.ClusterNamespace);
            await _kubernetes.CreateNamespaceAsync(@namespace);
        }
        catch (HttpOperationException hx)
        {
            // Kubernetes API - Invalid Request
            var errorMessage = KubernetesHelper.GetResponseMessage(hx.Response.Content);
            throw new Exception(errorMessage);
        }
        catch
        {
            throw;
        }
    }

    public async Task CreateDeploymentIfNotExistsAsync()
    {
        // Check if deployment exists
        if (await _clusterService.ValidateDeploymentByNameIfExistsAsync(DefaultConfigOptions.DeploymentName))
        {
            return;
        }

        // Initialize labels
        var labels = _clusterService.NewLabels(DefaultConfigOptions.AppName, _appProperties.PlanId);
        var adoURL= SecretsHelper.GetAdoUrl();
        var adoToken = SecretsHelper.GetADOToken();

        try
        {
            // Create deployment
            var deployment = _clusterService.NewDeployment(labels, _userConfigOptions.AgentCount, _userConfigOptions.ImageName, _userConfigOptions.ImageTag, _userConfigOptions.PoolName, adoURL, adoToken);
            await _kubernetes.CreateNamespacedDeploymentAsync(deployment, _userConfigOptions.ClusterNamespace);

            // Poller
            // TODO: Implement container poller
            await Task.Delay(30000);

            /*
            var availableReplicas = 0;
            do
            {
                var deployment = await client.ReadNamespacedDeploymentStatusAsync(DeploymentName, namespaceName);
                if (deployment.Status.AvailableReplicas is not null)
                {
                    availableReplicas = (int) deployment.Status.AvailableReplicas;
                }
                else
                {
                    availableReplicas = 0;
                }


            }
            while (availableReplicas == 0);
            */
        }
        catch (HttpRequestException hx)
        {
            // Kubernetes API - Connection Refused
            throw new Exception(hx.Message);
        }
        catch (HttpOperationException hx)
        {
            // Kubernetes API - Invalid Request
            var errorMessage = KubernetesHelper.GetResponseMessage(hx.Response.Content);
            throw new Exception(errorMessage);
        }
        catch
        {
            throw;
        }
    }

    // public async void DeleteNamespaceIfExistsAsync()
    // {
    //     // TODO: Implementation
    //     return;
    // }

    public async Task DeleteDeploymentIfExistsAsync()
    {
        // Initialize labels
        var labels = _clusterService.NewLabels(DefaultConfigOptions.AppName, _appProperties.PlanId);

        // Retrieve deployment
        var deployment = await _clusterService.GetDeploymentByPlanIdAsync(labels);

        // Check if deployment is empty
        if (deployment is null)
        {
            return;
        }

        try
        {
            // Delete deployment
            await _kubernetes.DeleteNamespacedDeploymentAsync(deployment.Name(), deployment.Namespace());
        }
        catch
        {
            throw;
        }
    }
}