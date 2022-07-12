using Pipelines.Runtime.Models;

namespace Pipelines.Runtime.Helpers;

public static class MessageHelper
{
    /// <summary>
    /// </summary>
    public static string TrimEncodingChars(string message)
    {
        var startChar = message.IndexOf("{", StringComparison.Ordinal);
        var endChar = message.LastIndexOf("}", StringComparison.Ordinal) + 1;
        var length = endChar - startChar;

        return message.Substring(startChar, length);
    }

    /// <summary>
    /// Parse application properties
    /// </summary>
    /// <param name="applicationProperties"></param>
    /// <returns></returns>
    public static ApplicationProperties ParseApplicationProperties(IReadOnlyDictionary<string, object> applicationProperties)
    {
        var taskProperties = new Dictionary<string, string>();
        foreach (var property in ApplicationProperties.PropertiesList)
        {
            if (applicationProperties.TryGetValue(property, out var propertyValues))
            {
                taskProperties.Add(property, propertyValues.ToString());
            }
        }

        return new ApplicationProperties(taskProperties);
    }

    public static UserConfigOptions ParseConfigurationOptions(BinaryData configData)
    {
        var configOptions = new UserConfigOptions();
        var configJson = configData.ToString();

        var config = JsonSerializer.Deserialize<UserConfigOptions>(configJson);
        if (config is null)
        {
            throw new Exception("Unable to deserialize message body");
        }

        return config;
    }

    /// <summary>
    /// Parse operation type
    /// </summary>

    public static OperationType ParseOperationType(ServiceBusReceivedMessage message)
    {
        message.ApplicationProperties.TryGetValue("Operation", out var operation);
        if (operation is null)
        {
            throw new Exception("Failed to parse operation from message");
        }

        operation = operation.ToString()?.ToLower();
        if (operation?.ToString() is "create")
        {
            return OperationType.Create;
        }

        if (operation?.ToString() is "delete")
        {
            return OperationType.Delete;
        }

        throw new Exception("Unknown operation");
    }

    public enum OperationType
    {
        Create,
        Delete
    }
}