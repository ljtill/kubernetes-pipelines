namespace Pipelines.Runtime.Models;

public class UserConfigOptions
{
    [JsonPropertyName("operation")]
    public string Operation { get; set; }

    [JsonPropertyName("poolName")]
    public string PoolName { get; set; }

    [JsonPropertyName("operatingSystem")]
    public string OperatingSystem { get; init; }

    [JsonPropertyName("imageName")]
    public string ImageName { get; init; }

    [JsonPropertyName("imageTag")]
    public string ImageTag { get; init; }

    [JsonPropertyName("agentCount")]
    public string AgentCount { get; init; }

    [JsonPropertyName("clusterNamespace")]
    public string ClusterNamespace { get; init; }
}
