using System.Collections.Concurrent;
using System.Text;
using System.Text.Json;
using Azure.Storage.Blobs;
using Microsoft.Azure.Relay;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Origo.Bifrost.Odbc.Agent;

public static class Program
{
    public static async Task<int> Main(string[] args)
    {
        // The child has no host, logger or Azure clients. Its stdout is only the sanitized protocol.
        if (args.Length == 2 && args[0] == "--execute-request")
        {
            try
            {
                var request = Protocol.Parse(await Protocol.ReadBoundedAsync(Console.OpenStandardInput(), CancellationToken.None));
                var result = new Database(Settings.FromEnvironment()).Execute(request, args[1]);
                string body = JsonSerializer.Serialize(result, Protocol.Json);
                Console.Write(Encoding.UTF8.GetByteCount(body) <= Settings.MaxBytes ? body : Protocol.Failure);
            }
            catch
            {
                Console.Write(Protocol.Failure);
            }
            return 0;
        }
        try
        {
            var settings = Settings.FromEnvironment();
            var builder = Host.CreateApplicationBuilder(new HostApplicationBuilderSettings
            {
                Args = args,
                ContentRootPath = AppContext.BaseDirectory
            });
            builder.Logging.ClearProviders();
            builder.Logging.AddSimpleConsole(options => options.SingleLine = true);
            builder.Services.AddWindowsService(options => options.ServiceName = "BifrostODBC");
            builder.Services.AddSingleton(settings);
            builder.Services.AddHostedService<RelayService>();
            await builder.Build().RunAsync();
            return Environment.ExitCode;
        }
        catch
        {
            // Configuration and library exception messages can include credentials.
            Console.Error.WriteLine("Bifrost ODBC could not start. Check the protected service configuration.");
            return 1;
        }
    }
}

public sealed class RelayService(Settings settings, ILogger<RelayService> logger, IHostApplicationLifetime lifetime) : BackgroundService
{
    private readonly SemaphoreSlim slots = new(4);
    private readonly ConcurrentDictionary<long, Task> inFlight = new();
    private long sequence;

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        try
        {
            await ListenAsync(stoppingToken);
        }
        catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
        {
        }
        catch
        {
            // Includes library/configuration constructors: never let the host log their exceptions.
            logger.LogError("Bifrost ODBC listener could not initialize.");
            Environment.ExitCode = 1;
            lifetime.StopApplication();
        }
    }

    private async Task ListenAsync(CancellationToken stoppingToken)
    {
        var listener = new HybridConnectionListener(Settings.Required("BIFROST_ODBC_RELAY_CONNECTION"));
        IBlobFiles? blobs = null;
        if (Environment.GetEnvironmentVariable("BIFROST_ODBC_BLOB_CONNECTION") is { Length: > 0 } blobConnection)
        {
            var options = new Azure.Storage.Blobs.BlobClientOptions();
            options.Diagnostics.IsLoggingEnabled = false;
            options.Diagnostics.IsLoggingContentEnabled = false;
            blobs = new BlobFiles(new BlobContainerClient(blobConnection, Settings.Required("BIFROST_ODBC_BLOB_CONTAINER"), options));
        }
        var handler = new RequestHandler(new RequestExecutor(settings), settings, blobs);
        listener.RequestHandler = context =>
        {
            long id = Interlocked.Increment(ref sequence);
            var task = ServeAsync(context, handler, stoppingToken);
            inFlight[id] = task;
            _ = task.ContinueWith(completed => { inFlight.TryRemove(id, out _); }, TaskScheduler.Default);
        };
        try
        {
            await listener.OpenAsync(stoppingToken);
            logger.LogInformation("Bifrost ODBC listener started.");
            using var timer = new PeriodicTimer(TimeSpan.FromMinutes(1));
            while (await timer.WaitForNextTickAsync(stoppingToken))
            {
                try
                {
                    if (blobs != null)
                        await blobs.CleanupAsync(false, stoppingToken);
                }
                catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
                {
                    break;
                }
                catch
                {
                    logger.LogWarning("Temporary blob cleanup will be retried.");
                }
            }
        }
        catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
        {
        }
        catch
        {
            logger.LogError("Bifrost ODBC listener failed.");
            Environment.ExitCode = 1;
            lifetime.StopApplication();
        }
        finally
        {
            try
            {
                await listener.CloseAsync(TimeSpan.FromSeconds(15));
                await Task.WhenAll(inFlight.Values);
                using var cleanup = new CancellationTokenSource(TimeSpan.FromSeconds(15));
                if (blobs != null)
                    await blobs.CleanupAsync(true, cleanup.Token);
            }
            catch
            {
                logger.LogWarning("Bifrost ODBC shutdown cleanup did not complete.");
            }
        }
    }

    private async Task ServeAsync(RelayedHttpListenerContext context, RequestHandler handler, CancellationToken token)
    {
        bool entered = false;
        try
        {
            entered = await slots.WaitAsync(0, token);
            context.Response.Headers["Content-Type"] = "application/json";
            if (!entered)
            {
                context.Response.StatusCode = System.Net.HttpStatusCode.TooManyRequests;
                return;
            }
            using var deadline = CancellationTokenSource.CreateLinkedTokenSource(token);
            deadline.CancelAfter(TimeSpan.FromSeconds(settings.MaxSeconds));
            string body = await Protocol.ReadBoundedAsync(context.Request.InputStream, deadline.Token);
            string result = await handler.HandleAsync(body, context.Request.HttpMethod, deadline.Token);
            byte[] bytes = Encoding.UTF8.GetBytes(result);
            await context.Response.OutputStream.WriteAsync(bytes, deadline.Token);
            logger.LogInformation("ODBC request completed.");
        }
        catch
        {
            logger.LogWarning("ODBC request failed.");
            try
            {
                context.Response.StatusCode = System.Net.HttpStatusCode.BadRequest;
                await context.Response.OutputStream.WriteAsync(Encoding.UTF8.GetBytes(Protocol.Failure), CancellationToken.None);
            }
            catch
            {
                // A disconnected caller must never surface raw library diagnostics.
            }
        }
        finally
        {
            try
            {
                context.Response.Close();
            }
            catch
            {
                logger.LogWarning("ODBC response could not be closed.");
            }
            finally
            {
                if (entered)
                    slots.Release();
            }
        }
    }
}
