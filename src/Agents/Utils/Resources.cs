using System.Threading.Tasks;
using System.Collections.Generic;
using Microsoft.Extensions.Logging;
using Microsoft.Azure.Management.Fluent;
using Microsoft.Azure.Management.ResourceManager.Fluent;
using Microsoft.Azure.Management.ResourceManager.Fluent.Core;

namespace Internal.Utils
{
    public static class Resources
    {
        public static async Task<IPagedCollection<IResourceGroup>> GetResourceGroups(ILogger log, IAzure azure)
        {
            IPagedCollection<IResourceGroup> resourceGroups = await azure.ResourceGroups.ListAsync();
            foreach (var group in resourceGroups)
            {
                log.LogInformation($"Group: {group.Name}");
            }

            return resourceGroups;
        }
        public static void CreateResourceGroup()
        { }
        public static void DeleteResourceGroup()
        { }
    }
}