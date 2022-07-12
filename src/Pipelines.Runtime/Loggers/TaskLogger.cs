using Pipelines.Runtime.Clients;

namespace Pipelines.Runtime.Loggers;

public class TaskLogger
{
    private readonly TaskClient _taskClient;
    private readonly List<string> _logMessages;

    public TaskLogger(TaskClient taskClient)
    {
        _taskClient = taskClient;
        _logMessages = new List<string>();
    }

    /// <summary>
    /// Write information log message
    /// </summary>
    /// <param name="logMessage"></param>
    public async Task LogInformationAsync(string logMessage)
    {
        _logMessages.Add(logMessage);
        await _taskClient.AppendTimelineRecordFeedAsync(new List<string>() { logMessage });
    }

    /// <summary>
    /// Write debug log message
    /// </summary>
    /// <param name="logMessage"></param>
    public async Task LogDebugAsync(string logMessage)
    {
        logMessage = $"[Debug] {logMessage}";
        _logMessages.Add(logMessage);

        await _taskClient.AppendTimelineRecordFeedAsync(new List<string>() { logMessage });

    }

    /// <summary>
    /// Write warning log message
    /// </summary>
    /// <param name="logMessage"></param>
    public async Task LogWarningAsync(string logMessage)
    {
        logMessage = $"[Warning] {logMessage}";
        _logMessages.Add(logMessage);

        await _taskClient.AppendTimelineRecordFeedAsync(new List<string>() { logMessage });

    }

    /// <summary>
    /// Write error log message
    /// </summary>
    /// <param name="logMessage"></param>
    public async Task LogErrorAsync(string logMessage)
    {
        logMessage = $"[Error] {logMessage}";
        _logMessages.Add(logMessage);

        await _taskClient.AppendTimelineRecordFeedAsync(new List<string>() { logMessage });
    }

    /// <summary>
    /// Upload the log messages
    /// </summary>
    public async Task UploadMessagesAsync()
    {
        await _taskClient.UploadTimelineRecordLogAsync(_logMessages);
    }
}