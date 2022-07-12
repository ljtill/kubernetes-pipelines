global using System;
global using Microsoft.Azure.WebJobs;
global using Microsoft.Azure.WebJobs.Host;
global using Microsoft.Extensions.Logging;

global using System.Collections.Generic;
global using System.IO;
global using System.Linq;
global using System.Net.Http;
global using System.Text.Json;
global using System.Text.Json.Serialization;
global using System.Threading.Tasks;

global using Azure.Messaging.ServiceBus;

global using k8s;
global using k8s.Autorest;
global using k8s.Models;

global using Microsoft.VisualStudio.Services.Common;
global using Microsoft.VisualStudio.Services.WebApi;

// NOTE: Moved to relative classes to avoid conflicts
//global using Microsoft.TeamFoundation.DistributedTask.WebApi;
//global using Microsoft.TeamFoundation.Build.WebApi;