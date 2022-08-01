
/*
 * Examples
 */

// dotnet run -- send --namespace <value> --queue <value> --operation <value>
// dotnet run -- send --namespace <value> --queue <value> --operation <value> --count 25
// dotnet run -- receive --namespace <value> --queue <value>
// dotnet run -- receive --namespace <value> --queue <value> --all
// dotnet run -- clear --namespace <value> --queue <value>

using Clients;

/*
 * Commands
 */

var sendCommand = new Command("send")
{
    new Option<string>("--namespace"),
    new Option<string>("--queue"),
    new Option<string>("--operation"),
    new Option<int>("--count", getDefaultValue: () => 1),
};

var receiveCommand = new Command("receive")
{
    new Option<string>("--namespace"),
    new Option<string>("--queue"),
    new Option<bool>("--all")
};

var clearCommand = new Command("clear")
{
    new Option<string>("--namespace"),
    new Option<string>("--queue")
};

var rootCommand = new RootCommand("")
{
    sendCommand,
    receiveCommand
};

/*
 * Handlers
 */

sendCommand.Handler = CommandHandler.Create(async (string @namespace, string queue, string operation, int count) =>
{
    Console.WriteLine($"[Command] Send command invoked");
    var client = new ServiceBusClient($"{@namespace}.servicebus.windows.net", new AzureCliCredential());

    if (count > 1)
    {
        await SendMessagesAsync(client, queue, operation, count);
        return;
    }

    await SendMessageAsync(client, queue, operation);
});

receiveCommand.Handler = CommandHandler.Create(async (string @namespace, string queue, bool all) =>
{
    Console.WriteLine($"[Command] Receive command invoked");
    var client = new ServiceBusClient($"{@namespace}.servicebus.windows.net", new AzureCliCredential());

    if (all)
    {
        await ReceiveMessagesAsync(client, queue);
        return;
    }

    await ReceiveMessageAsync(client, queue);
});

clearCommand.Handler = CommandHandler.Create(async (string @namespace, string queue) =>
{
    Console.WriteLine("[Command] Clear command invoked");
    var client = new ServiceBusClient($"{@namespace}.servicebus.windows.net", new AzureCliCredential());
    
    await ClearMessagesAsync(client, queue);
});

return rootCommand.Invoke(args);

/*
 * Methods
 */

async Task SendMessageAsync(ServiceBusClient client, string queue, string operation)
{
    var sender = client.CreateSender(queue);

    var messageBody = JsonSerializer.Serialize(new Message());
    var message = new ServiceBusMessage(messageBody)
    {
        ContentType = "application/json"
    };
    
    message.ApplicationProperties.Add("Operation", operation);

    try
    {
        Console.WriteLine($"[Handler] Sending message");
        await sender.SendMessageAsync(message);
    }
    catch (Exception ex)
    {
        Console.WriteLine($"[Error] Unable to send message -- ${ex.Message}");
    }
}

async Task SendMessagesAsync(ServiceBusClient client, string queue, string operation, int count)
{
    var sender = client.CreateSender(queue);

    var messageBody = JsonSerializer.Serialize(new Message());
    var message = new ServiceBusMessage(messageBody);
    message.ContentType = "application/json";
    message.ApplicationProperties.Add("Operation", operation);

    try
    {
        for (var i = 0; i <= count; i++)
        {
            Console.WriteLine($"[Handler] Sending message - {i}");
            await sender.SendMessageAsync(message);
        }
    }
    catch (Exception ex)
    {
        Console.WriteLine($"[Error] Unable to send message -- ${ex.Message}");
    }
}

async Task ReceiveMessageAsync(ServiceBusClient client, string queue)
{
    var receiver = client.CreateReceiver(queue, new ServiceBusReceiverOptions
    {
        ReceiveMode = ServiceBusReceiveMode.ReceiveAndDelete
    });

    try
    {
        var message = await receiver.ReceiveMessageAsync();
        Console.WriteLine($"[Handler] Receiving content - {message.Body}");
        await receiver.CompleteMessageAsync(message);
    }
    catch (Exception ex)
    {
        Console.WriteLine($"[Error] Unable to receive message -- ${ex.Message}");
    }
}

async Task ReceiveMessagesAsync(ServiceBusClient client, string queue)
{
    var receiver = client.CreateReceiver(queue, new ServiceBusReceiverOptions
    {
        ReceiveMode = ServiceBusReceiveMode.ReceiveAndDelete 
    });
    
    var messageCount = 0;

    try
    {
        do
        {
            var messageBatch = await receiver.ReceiveMessagesAsync(25, TimeSpan.FromSeconds(5));

            if (messageBatch.Count == 0)
            {
                break;
            }

            foreach (var message in messageBatch)
            {
                var messageId = message.MessageId.Substring(0, 8);
                Console.WriteLine($"[Handler] Receiving message - {messageCount} - {messageId}");
                await receiver.CompleteMessageAsync(message);
                messageCount++;
            }
        }
        while (true);
    }
    catch (Exception ex)
    {
        Console.WriteLine($"[Error] Unable to receive message -- ${ex.Message}");
    }
}

async Task ClearMessagesAsync(ServiceBusClient client, string queue)
{
    var receiver = client.CreateReceiver(queue, new ServiceBusReceiverOptions
    {
        ReceiveMode = ServiceBusReceiveMode.ReceiveAndDelete
    });

    try
    {
        while ((await receiver.PeekMessageAsync()) != null)
        {
            await receiver.ReceiveMessagesAsync(100);
        }
    }
    catch (Exception e)
    {
        Console.WriteLine(e);
        return;
    }
    
    Console.WriteLine("[Handler] Cleared messages");
}