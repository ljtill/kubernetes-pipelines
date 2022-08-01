namespace Clients;

public class Message
{
    [JsonPropertyName("operation")]
    public string Operation { get; set; } = "create";

    [JsonPropertyName("poolName")]
    public string PoolName { get; set; } = "default";

    [JsonPropertyName("operatingSystem")]
    public string OperatingSystem { get; init; } = "linux";

    [JsonPropertyName("imageName")]
    public string ImageName { get; init; } = "ubuntu";

    [JsonPropertyName("imageTag")]
    public string ImageTag { get; init; } = "latest";

    [JsonPropertyName("agentCount")]
    public string AgentCount { get; init; } = "1";

    [JsonPropertyName("clusterNamespace")]
    public string ClusterNamespace { get; init; } = "pipelines";
}