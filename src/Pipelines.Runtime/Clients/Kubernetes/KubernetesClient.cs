namespace Pipelines.Runtime.Clients;

public class KubernetesClient : k8s.Kubernetes
{
    public KubernetesClient(KubernetesClientConfiguration config, params DelegatingHandler[] handlers) : base(config, handlers)
    {
    }
}