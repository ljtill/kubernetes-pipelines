using Pipelines.Runtime.Clients;
using Pipelines.Runtime.Loggers;

namespace Pipelines.Runtime.Functions;

public class Create
{
    [FunctionName("Create")]
    public async Task Run([ServiceBusTrigger("create", Connection = "ServiceBusConnection")] ServiceBusReceivedMessage receivedMessage)
    {
        using var taskClient = new TaskClient(receivedMessage.ApplicationProperties);
        var taskLogger = new TaskLogger(taskClient);

        try
        {
            var clusterClient = new ClusterClient(receivedMessage.ApplicationProperties, receivedMessage.Body, taskLogger);

            await clusterClient.CreateNamespaceIfNotExistsAsync();

            await clusterClient.CreateDeploymentIfNotExistsAsync();
        }
        catch (Exception ex)
        {
            await taskClient.ReportTaskFailedAsync();
            await taskLogger.LogErrorAsync(ex.Message);
        }
        finally
        {
            taskClient.Dispose();
        }
    }
}