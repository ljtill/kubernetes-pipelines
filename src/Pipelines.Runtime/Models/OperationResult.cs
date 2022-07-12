namespace Pipelines.Runtime.Models;

public class OperationResult
{
    [JsonPropertyName("kind")]
    public string Kind { get; set; }

    [JsonPropertyName("apiVersion")]
    public string ApiVersion { get; set; }

    //[JsonPropertyName("metadata")]
    //public string Metadata { get; set; }

    [JsonPropertyName("status")]
    public string Status { get; set; }

    [JsonPropertyName("message")]
    public string Message { get; set; }

    [JsonPropertyName("reason")]
    public string Reason { get; set; }

    [JsonPropertyName("details")]
    public OperationResultDetails Details { get; set; }

    [JsonPropertyName("code")]
    public int Code { get; set; }
}

public class OperationResultDetails
{
    [JsonPropertyName("name")]
    public string Name { get; set; }

    [JsonPropertyName("group")]

    public string Group { get; set; }

    [JsonPropertyName("kind")]
    public string Kind { get; set; }
}