using Pipelines.Runtime.Helpers;
using Pipelines.Runtime.Models;
using Microsoft.TeamFoundation.DistributedTask.WebApi;

namespace Pipelines.Runtime.Clients;

public class TaskClient : IDisposable
{
    private readonly ApplicationProperties _taskProperties;
    private TaskHttpClient _taskHttpClient;

    public TaskClient(IReadOnlyDictionary<string, object> applicationProperties)
    {
        _taskProperties = MessageHelper.ParseApplicationProperties(applicationProperties);

        var vssBasicCredential = new VssBasicCredential(string.Empty, _taskProperties.AuthToken);
        var vssConnection = new VssConnection(_taskProperties.PlanUri, vssBasicCredential);
        _taskHttpClient = vssConnection.GetClient<TaskHttpClient>();
    }

    /// <summary>
    /// Update task status to started
    /// </summary>
    public async Task ReportTaskStartedAsync()
    {
        var startedEvent = new TaskStartedEvent(_taskProperties.JobId, _taskProperties.TaskInstanceId);
        await _taskHttpClient.RaisePlanEventAsync(_taskProperties.ProjectId, _taskProperties.HubName, _taskProperties.PlanId, startedEvent);
    }

    /// <summary>
    /// Update task status to completed
    /// </summary>
    /// <param name="result"></param>
    public async Task ReportTaskCompletedAsync()
    {
        var completedEvent = new TaskCompletedEvent(_taskProperties.JobId, _taskProperties.TaskInstanceId, TaskResult.Succeeded);
        await _taskHttpClient.RaisePlanEventAsync(_taskProperties.ProjectId, _taskProperties.HubName, _taskProperties.PlanId, completedEvent);
    }

    /// <summary>
    /// Update task status to failed
    /// </summary>
    public async Task ReportTaskFailedAsync()
    {
        var failedEvent = new TaskCompletedEvent(_taskProperties.JobId, _taskProperties.TaskInstanceId, TaskResult.Failed);
        await _taskHttpClient.RaisePlanEventAsync(_taskProperties.ProjectId, _taskProperties.HubName, _taskProperties.PlanId, failedEvent);
    }

    /// <summary>
    /// Append record feed with log messages
    /// </summary>
    /// <param name="logLines"></param>
    public async Task AppendTimelineRecordFeedAsync(IEnumerable<string> logLines)
    {
        await _taskHttpClient.AppendTimelineRecordFeedAsync(_taskProperties.ProjectId, _taskProperties.HubName,
            _taskProperties.PlanId, _taskProperties.TimelineId, _taskProperties.JobId, new[] { $"{logLines}" });
    }

    /// <summary>
    /// Upload log messages
    /// </summary>
    public async Task UploadTimelineRecordLogAsync(List<string> logMessages)
    {
        var log = new TaskLog(string.Format(@"logs\{0:D}", _taskProperties.TaskInstanceId));
        var taskLog = await _taskHttpClient.CreateLogAsync(_taskProperties.ProjectId, _taskProperties.HubName, _taskProperties.PlanId, log);

        using (var memoryStream = new MemoryStream())
        {
            var streamWriter = new StreamWriter(memoryStream);

            foreach (var logMessage in logMessages)
            {
                await streamWriter.WriteAsync(logMessage);
                await streamWriter.FlushAsync();
            }

            memoryStream.Position = 0;

            await _taskHttpClient.AppendLogContentAsync(_taskProperties.ProjectId, _taskProperties.HubName, _taskProperties.PlanId, taskLog.Id, memoryStream);
        }

        var updateRecord = new TimelineRecord
        {
            Id = _taskProperties.TaskInstanceId,
            Log = taskLog
        };

        await _taskHttpClient.UpdateTimelineRecordsAsync(_taskProperties.ProjectId, _taskProperties.HubName, _taskProperties.PlanId, _taskProperties.TimelineId, new List<TimelineRecord> { updateRecord });
    }

    /// <summary>
    /// Implement dispose functionality
    /// </summary>
    public void Dispose()
    {
        _taskHttpClient?.Dispose();
        _taskHttpClient = null;
    }
}
