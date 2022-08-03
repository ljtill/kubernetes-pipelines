namespace Pipelines.Runtime.Models;

public class ApplicationProperties
{
    public Guid ProjectId { get; set; }
    public Guid PlanId { get; set; }
    public Uri PlanUri { get; set; }
    public Guid JobId { get; set; }
    public Guid TimelineId { get; set; }
    public int DefinitionId { get; set; }
    public string AuthToken { get; set; }
    public string HubName { get; set; }
    public Guid TaskInstanceId { get; set; }
    public string TaskInstanceName { get; set; }
    public RequestType RequestType { get; set; }

    private static readonly List<string> MandatoryProperties = new List<string>
    {
        ProjectIdKey,
        PlanIdKey,
        PlanUrlKey,
        JobIdKey,
        TimelineIdKey,
        DefinitionIdKey,
        AuthTokenKey,
    };

    public static readonly List<string> PropertiesList = new List<string>(MandatoryProperties)
    {
        HubNameKey,
        TaskInstanceIdKey,
        TaskInstanceNameKey,
        RequestTypeKey,
    };

    private const string ProjectIdKey = "ProjectId";
    private const string PlanIdKey = "PlanId";
    private const string PlanUrlKey = "PlanUrl";
    private const string JobIdKey = "JobId";
    private const string TimelineIdKey = "TimelineId";
    private const string DefinitionIdKey = "DefinitionId";
    private const string AuthTokenKey = "AuthToken";
    private const string HubNameKey = "HubName";
    private const string TaskInstanceIdKey = "TaskInstanceId";
    private const string TaskInstanceNameKey = "TaskInstanceName";
    private const string RequestTypeKey = "RequestType";

    public ApplicationProperties(IDictionary<string, string> messageProperties)
    {
        var missingProperties = MandatoryProperties.Where(propertyToCheck => !messageProperties.ContainsKey(propertyToCheck)).ToList();
        if (missingProperties.Any())
        {
            throw new Exception($"Required properties {string.Join(", ", missingProperties)} are missing");
        }

        this.ProjectId = ParseGuid(messageProperties, ProjectIdKey);
        this.PlanId = ParseGuid(messageProperties, PlanIdKey);
        this.PlanUri = ParseUri(messageProperties, PlanUrlKey);
        this.JobId = ParseGuid(messageProperties, JobIdKey);
        this.TimelineId = ParseGuid(messageProperties, TimelineIdKey);
        this.DefinitionId = int.Parse(messageProperties[DefinitionIdKey]);
        this.AuthToken = messageProperties[AuthTokenKey];
        this.HubName = messageProperties[HubNameKey];
        this.TaskInstanceId = ParseGuid(messageProperties, TaskInstanceIdKey);
        this.TaskInstanceName = messageProperties[TaskInstanceNameKey];
        this.RequestType = ParseRequestType(messageProperties, RequestTypeKey);
    }

    // TODO: Move these methods into the TaskHelper class
    private static Guid ParseGuid(IDictionary<string, string> messageProperties, string propertyName)
    {
        var messageProperty = messageProperties[propertyName];
        if (!Guid.TryParse(messageProperty, out var propertyValue))
        {
            throw new Exception($"Invalid GUID value {messageProperty} provided for {propertyName}");
        }

        return propertyValue;
    }

    private static Uri ParseUri(IDictionary<string, string> messageProperties, string propertyName)
    {
        var messageProperty = messageProperties[propertyName];
        if (!Uri.TryCreate(messageProperty, UriKind.Absolute, out var propertyValue))
        {
            throw new Exception($"Invalid URI value {messageProperty} property for {propertyName}");
        }

        return propertyValue;
    }

    private static RequestType ParseRequestType(IDictionary<string, string> messageProperties, string propertyName)
    {
        // Set request type default value
        var requestTypeValue = Models.RequestType.Execute.ToString();

        // If value exists, overwrite default
        if (messageProperties.ContainsKey(propertyName))
        {
            requestTypeValue = messageProperties[propertyName];
        }

        // Try parsing the request type
        Enum.TryParse<RequestType>(requestTypeValue, out var propertyValue);

        return propertyValue;
    }
}