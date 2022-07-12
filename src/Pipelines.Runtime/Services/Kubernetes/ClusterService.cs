using Pipelines.Runtime.Clients;
using Pipelines.Runtime.Loggers;

namespace Pipelines.Runtime.Services;

public class ClusterService
{
    private readonly KubernetesClient _kubernetesClient;
    private readonly TaskLogger _taskLogger;

    public ClusterService(KubernetesClient kubernetesClient, TaskLogger taskLogger)
    {
        _kubernetesClient = kubernetesClient;
        _taskLogger = taskLogger;
    }

    // Validate

    public async Task<bool> ValidateNamespaceByNameIfExistsAsync(string name)
    {
        V1NamespaceList namespaceList;

        try
        {
            namespaceList = await GetNamespacesAsync();
        }
        catch
        {
            throw;
        }

        // Search the list for the user define namespace
        var @namespace = namespaceList.Items.FirstOrDefault(ns => ns.Metadata.Name == name);

        // Namespace does not exist
        return @namespace is not null;
    }

    public async Task<bool> ValidateDeploymentByNameIfExistsAsync(string name)
    {
        var deployments = await GetDeploymentsAsync();

        // Search the list of deployment
        var deployment = deployments.Items.FirstOrDefault(dp => dp.Metadata.Name == name);

        // Deployment does not exist
        return deployment is not null;
    }

    // Get

    public async Task<V1DeploymentList> GetDeploymentsAsync()
    {
        V1DeploymentList deploymentList;

        try
        {
            // Retrieve all deployments from the Kubernetes API
            deploymentList = await _kubernetesClient.ListDeploymentForAllNamespacesAsync();
        }
        catch (HttpRequestException hx)
        {
            // Kubernetes API - Request Failed
            throw new Exception(hx.Message);
        }

        // List validation
        if (deploymentList.Items.Count == 0)
        {
            throw new Exception("Returned deployment list is empty");
        }

        return deploymentList;
    }

    public async Task<V1Deployment> GetDeploymentByPlanIdAsync(Dictionary<string, string> labels)
    {
        V1DeploymentList deploymentList;

        try
        {
            // Retrieve all deployments from the Kubernetes API
            deploymentList = await _kubernetesClient.ListDeploymentForAllNamespacesAsync();
        }
        catch (HttpRequestException hx)
        {
            // Kubernetes API - Request Failed
            throw new Exception(hx.Message);
        }

        // List validation
        if (deploymentList.Items.Count == 0)
        {
            throw new Exception("Returned deployment list is empty");
        }

        // Iterate through the deployments
        foreach (var deployment in deploymentList.Items)
        {
            deployment.Labels().TryGetValue("planId", out var planId);
            if (planId == labels["planId"])
            {
                return deployment;
            }
        }

        return null;
    }

    public async Task<V1NamespaceList> GetNamespacesAsync()
    {
        V1NamespaceList namespaceList;

        try
        {
            // Retrieve all namespaces from the Kubernetes API
            namespaceList = await _kubernetesClient.ListNamespaceAsync();
        }
        catch (HttpRequestException hx)
        {
            // Kubernetes API - Request Failed
            throw new Exception(hx.Message);
        }

        // List validation
        if (namespaceList.Items.Count == 0)
        {
            throw new Exception("Returned namespace list is empty");
        }

        return namespaceList;
    }

    // New

    public V1Namespace NewNamespace(string name)
    {
        return new V1Namespace
        {
            Metadata = new V1ObjectMeta
            {
                Name = name
            }
        };
    }

    public V1Deployment NewDeployment(Dictionary<string, string> labels, string agentCount, string imageName, string imageTag, string poolName)
    {
        return new V1Deployment
        {
            ApiVersion = "apps/v1",
            Kind = "Deployment",
            Metadata = new V1ObjectMeta
            {
                Name = "agents",
                Labels = labels
            },
            Spec = new V1DeploymentSpec
            {
                Replicas = Int32.Parse(agentCount),
                Selector = new V1LabelSelector
                {
                    MatchLabels = labels
                },
                Template = new V1PodTemplateSpec
                {
                    Metadata = new V1ObjectMeta
                    {
                        Labels = labels
                    },
                    Spec = new V1PodSpec
                    {
                        Containers = new List<V1Container>
                        {
                            new()
                            {
                                Name = "agent",
                                Image = $"{imageName}:{imageTag}",
                                Env = new List<V1EnvVar>
                                {
                                    new()
                                    {
                                        Name = "AZP_URL",
                                        Value = "https://dev.azure.com/lytill"
                                    },
                                    new()
                                    {
                                        Name = "AZP_TOKEN",
                                        ValueFrom = new V1EnvVarSource
                                        {
                                            SecretKeyRef = new V1SecretKeySelector
                                            {
                                                Name = "azure",
                                                Key = "token"
                                            }
                                        }
                                    },
                                    new()
                                    {
                                        Name = "AZP_POOL",
                                        Value = poolName
                                    },
                                    // new()
                                    // {
                                    //     Name = "Build.Agent",
                                    //     Value = message.X
                                    // }
                                }
                            }
                        },
                        ImagePullSecrets = new List<V1LocalObjectReference>
                        {
                            new()
                            {
                                Name = "nekwgxnn"
                            }
                        }
                    }
                }
            },
        };
    }

    public Dictionary<string, string> NewLabels(string name, Guid planId)
    {
        return new Dictionary<string, string>
        {
            {
                "app",
                name
            },
            {
                "planId",
                planId.ToString()
            }
        };
    }
}