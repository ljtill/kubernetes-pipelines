namespace Pipelines.Runtime.Functions;

public class Maintain
{
    [FunctionName("Maintain")]
    public void Run([TimerTrigger("0 */5 * * * *")] TimerInfo myTimer, ILogger log)
    {
        log.LogInformation($"C# Timer trigger function executed at: {DateTime.Now}");
    }
}
