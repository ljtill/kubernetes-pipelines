using Azure.Identity;
using Azure.ResourceManager;
using Azure.ResourceManager.Resources;
using Azure.ResourceManager.KeyVault;
using Azure.Security.KeyVault.Secrets;

namespace Pipelines.Runtime.Helpers;
public static class SecretsHelper
{
    public static Uri GetKeyVaultUri()
    {
        var resourceManagerClient = new ArmClient(new DefaultAzureCredential());
        SubscriptionResource subscription = resourceManagerClient.GetDefaultSubscription();
        ResourceGroupCollection resourceGroups = subscription.GetResourceGroups();
        ResourceGroupResource resourceGroup = resourceGroups.FirstOrDefault();
        KeyVaultResource keyVault = resourceGroup.GetKeyVaults().FirstOrDefault();

        return keyVault.Data.Properties.VaultUri;
    }
    public static string GetADOToken()
    {
        string secretName = "ADO_Token";
        Uri uri = GetKeyVaultUri();
        var client = new SecretClient(vaultUri: uri, new DefaultAzureCredential());
        var secret = client.GetSecret(secretName);

        return secret.ToString();
    }

    public static string GetAdoUrl()
    {
        string secretName = "ADO_URL";
        Uri uri = GetKeyVaultUri();
        var client = new SecretClient(vaultUri: uri, new DefaultAzureCredential());
        var secret = client.GetSecret(secretName);

        return secret.ToString();
    }
}
