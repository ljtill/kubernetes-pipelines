using Pipelines.Runtime.Clients;
using Pipelines.Runtime.Helpers;
using Pipelines.Runtime.Loggers;

namespace Pipelines.Runtime.Functions;

public class Process
{
    [FunctionName("Process")]
    public async Task Run(
        [ServiceBusTrigger("process", Connection = "ServiceBusConnection")] ServiceBusReceivedMessage receivedMessage,
        [ServiceBus("create", Connection = "ServiceBusConnection")] IAsyncCollector<ServiceBusMessage> sendCreateMessage,
        [ServiceBus("delete", Connection = "ServiceBusConnection")] IAsyncCollector<ServiceBusMessage> sendDeleteMessage)
    {
        using var buildClient = new BuildClient(receivedMessage.ApplicationProperties);

        try
        {
            await buildClient.ValidateBuildStatusAsync();
        }
        catch
        {
            // TODO(ljtill): Write to runtime logger
            return;
        }
        finally
        {
            buildClient.Dispose();
        }

        using var taskClient = new TaskClient(receivedMessage.ApplicationProperties);
        var taskLogger = new TaskLogger(taskClient);

        try
        {
            // Update the pipeline status to started
            await taskClient.ReportTaskStartedAsync();

            // Parse the incoming message
            var operation = MessageHelper.ParseOperationType(receivedMessage);

            // Push the message onto the create queue
            if (operation == MessageHelper.OperationType.Create)
            {
                await taskLogger.LogDebugAsync("Sending message to the create queue");
                await sendCreateMessage.AddAsync(NewMessage(receivedMessage));
            }

            // Push the message onto the delete queue
            if (operation == MessageHelper.OperationType.Delete)
            {
                await taskLogger.LogDebugAsync("Sending message to the delete queue");
                await sendDeleteMessage.AddAsync(NewMessage(receivedMessage));
            }

            // Upload logs to pipeline
            await taskLogger.UploadMessagesAsync();

            // Update the pipeline status to completed
            await taskClient.ReportTaskCompletedAsync();
        }
        catch (Exception ex)
        {
            await taskClient.ReportTaskFailedAsync();
            await taskLogger.LogErrorAsync(ex.Message);

            // Upload logs to pipeline
            // TODO(ljtill): Review this design
            await taskLogger.UploadMessagesAsync();
        }
        finally
        {
            taskClient.Dispose();
        }
    }

    private ServiceBusMessage NewMessage(ServiceBusReceivedMessage message)
    {
        var sendMessage = new ServiceBusMessage();

        var messageBody = MessageHelper.TrimEncodingChars(message.Body.ToString());
        sendMessage.Body = BinaryData.FromString(messageBody);

        foreach (var property in message.ApplicationProperties)
        {
            sendMessage.ApplicationProperties.Add(property.Key, property.Value);
        }

        return sendMessage;
    }

}