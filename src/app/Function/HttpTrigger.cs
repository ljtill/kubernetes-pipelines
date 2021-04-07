using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Microsoft.Azure.Management.ResourceManager.Fluent;

using Internal.Utils;

namespace Internal.Function
{
    public static class Agents
    {
        [FunctionName("agents")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "get", Route = null)] HttpRequest req,
            ILogger log)
        {
            log.LogInformation("C# HTTP trigger function processed a request.");

            // Configuration
            string resourceGroupName = SdkContext.RandomResourceName("rg-aci-", 6);

            // Context
            Context.GetContext(log);

            // Resource Group

            // Container Group

            string responseMessage = "Sample response";

            return new OkObjectResult(responseMessage);
        }
    }
}
