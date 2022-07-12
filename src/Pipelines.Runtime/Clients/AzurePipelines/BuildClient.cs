using Pipelines.Runtime.Helpers;
using Pipelines.Runtime.Models;
using Microsoft.TeamFoundation.Build.WebApi;

namespace Pipelines.Runtime.Clients;

public class BuildClient : IDisposable
{
    private readonly ApplicationProperties _buildProperties;
    private BuildHttpClient _buildHttpClient;

    public BuildClient(IReadOnlyDictionary<string, object> applicationProperties)
    {
        _buildProperties = MessageHelper.ParseApplicationProperties(applicationProperties);

        var vssBasicCredential = new VssBasicCredential(string.Empty, _buildProperties.AuthToken);
        var vssConnection = new VssConnection(_buildProperties.PlanUri, vssBasicCredential);
        _buildHttpClient = vssConnection.GetClient<BuildHttpClient>();
    }

    /// <summary>
    /// Validate that the build is active
    /// </summary>
    public async Task ValidateBuildStatusAsync()
    {
        var build = await GetBuildAsync();
        if (build.Status != BuildStatus.InProgress)
        {
            throw new Exception("Build is not in progress");
        }
    }

    /// <summary>
    /// Retrieve all builds
    /// </summary>
    private async Task<Build> GetBuildAsync()
    {
        IEnumerable<int> definitionIds = new[] { _buildProperties.DefinitionId };
        var builds = await _buildHttpClient.GetBuildsAsync(_buildProperties.ProjectId, definitionIds);

        var build = builds.FirstOrDefault(x => x.OrchestrationPlan.PlanId == _buildProperties.PlanId);
        if (build is null)
        {
            throw new Exception("Unable to locate build with plan id: " + _buildProperties.PlanId);
        }

        return build;
    }

    public void Dispose()
    {
        _buildHttpClient?.Dispose();
        _buildHttpClient = null;
    }
}