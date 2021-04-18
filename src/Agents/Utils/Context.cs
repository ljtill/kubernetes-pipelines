using System;
using Microsoft.Extensions.Logging;
using Microsoft.Azure.Management.Fluent;
using Microsoft.Azure.Management.ResourceManager.Fluent;
using Microsoft.Azure.Management.ResourceManager.Fluent.Authentication;

namespace Internal.Utils
{
    public static class Context
    {
        private enum Platform
        {
            Local,
            Cloud
        }

        /// <summary>
        /// Returns an authenticated Azure context.
        /// </summary>
        /// <param name="log"></param>
        /// <returns>Authenticated IAzure context.</returns>
        public static IAzure GetContext(ILogger log)
        {
            IAzure azure;

            Platform platform = GetPlatform(log);
            var credential = GetCredential(log, platform);

            try
            {
                azure = Azure.Authenticate(credential).WithDefaultSubscription();
            }
            catch (Exception e)
            {
                log.LogError("Unable to authenticate with Azure.");
                throw new Exception(e.Message);
            }

            return azure;
        }

        /// <summary>
        /// Return a Platform type.
        /// </summary>
        /// <param name="log"></param>
        /// <returns>Platform enum.</returns>
        private static Platform GetPlatform(ILogger log)
        {
            // How should we handle platform detection?
            log.LogDebug("Platform {0}", "Local");

            return Platform.Local;
        }

        private static AzureCredentials GetCredential(ILogger log, Platform platform)
        {
            AzureCredentials credential;

            switch (platform)
            {
                case Platform.Local:
                    string clientId = GetVariable("AzureClientId");
                    string clientSecret = GetVariable("AzureClientSecret");
                    string tenantId = GetVariable("AzureTenantId");

                    credential = new AzureCredentialsFactory().FromServicePrincipal(clientId, clientSecret, tenantId, AzureEnvironment.AzureGlobalCloud);
                    break;
                case Platform.Cloud:
                    credential = new AzureCredentialsFactory().FromSystemAssignedManagedServiceIdentity(MSIResourceType.AppService, AzureEnvironment.AzureGlobalCloud);
                    break;
                default:
                    throw new Exception("Unable to detect platform");
            }

            return credential;
        }

        /// <summary>
        /// Returns an environment variable value.
        /// </summary>
        /// <param name="name"></param>
        /// <returns>Environment variabe.</returns>
        private static string GetVariable(string name)
        {
            return Environment.GetEnvironmentVariable(name);
        }
    }
}