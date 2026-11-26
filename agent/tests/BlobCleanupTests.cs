using System.Collections.Concurrent;
using System.Globalization;
using System.Net;
using System.Net.Sockets;
using System.Text;
using Azure.Storage.Blobs;
using Origo.Bifrost.Odbc.Agent;
using Xunit;

namespace Bifrost.Odbc.Agent.Tests;

public sealed class BlobCleanupTests
{
    // A real SDK client talks only to a loopback fixture inside this worker container.
    private sealed class Storage : IAsyncDisposable
    {
        private readonly HttpListener listener = new();
        private readonly Task loop;
        public ConcurrentDictionary<string, byte[]> Files { get; } = new();
        public int Deletes;
        public BlobFiles Client { get; }

        public Storage()
        {
            var port = new TcpListener(IPAddress.Loopback, 0);
            port.Start();
            int number = ((IPEndPoint)port.LocalEndpoint).Port;
            port.Stop();
            string endpoint = $"http://127.0.0.1:{number}/";
            listener.Prefixes.Add(endpoint);
            listener.Start();
            var options = new BlobClientOptions();
            options.Retry.MaxRetries = 0;
            options.Diagnostics.IsLoggingEnabled = false;
            options.Diagnostics.IsLoggingContentEnabled = false;
            Client = new BlobFiles(new BlobContainerClient(new Uri(endpoint + "xaccount/xtemporary"), options));
            loop = ServeAsync();
        }

        private async Task ServeAsync()
        {
            while (listener.IsListening)
            {
                HttpListenerContext context;
                try
                {
                    context = await listener.GetContextAsync();
                }
                catch (HttpListenerException)
                {
                    break;
                }
                catch (ObjectDisposedException)
                {
                    break;
                }
                try
                {
                    var response = context.Response;
                    string name = context.Request.Url!.Segments.Last();
                    response.Headers["ETag"] = "\"XFixture\"";
                    response.Headers["Last-Modified"] = DateTimeOffset.UtcNow.ToString("R", CultureInfo.InvariantCulture);
                    response.Headers["x-ms-request-id"] = "XRequest";
                    response.Headers["x-ms-blob-type"] = "BlockBlob";
                    if (context.Request.HttpMethod == "PUT")
                    {
                        using var data = new MemoryStream();
                        await context.Request.InputStream.CopyToAsync(data);
                        Files[name] = data.ToArray();
                        response.StatusCode = 201;
                    }
                    else if (context.Request.HttpMethod == "DELETE")
                    {
                        Files.TryRemove(name, out _);
                        Interlocked.Increment(ref Deletes);
                        response.StatusCode = 202;
                    }
                    else if (Files.TryGetValue(name, out var data))
                    {
                        long start = 0;
                        long end = data.Length - 1;
                        string? range = context.Request.Headers["x-ms-range"] ?? context.Request.Headers["Range"];
                        if (range != null)
                        {
                            var parts = range["bytes=".Length..].Split('-');
                            start = long.Parse(parts[0], CultureInfo.InvariantCulture);
                            if (parts[1].Length > 0)
                                end = Math.Min(end, long.Parse(parts[1], CultureInfo.InvariantCulture));
                            response.StatusCode = 206;
                            response.Headers["Content-Range"] = $"bytes {start}-{end}/{data.Length}";
                        }
                        response.ContentLength64 = end - start + 1;
                        if (context.Request.HttpMethod != "HEAD")
                            await response.OutputStream.WriteAsync(data.AsMemory((int)start, (int)(end - start + 1)));
                    }
                    else
                        response.StatusCode = 404;
                }
                catch (IOException)
                {
                    // Oversized/cancelled readers can close the loopback socket early.
                }
                finally
                {
                    context.Response.Close();
                }
            }
        }

        public async ValueTask DisposeAsync()
        {
            listener.Close();
            await loop;
        }
    }

    [Fact]
    public async Task DownloadDeletesItsRequestBlob()
    {
        await using var storage = new Storage();
        string id = Guid.NewGuid().ToString("D");
        storage.Files[id] = Encoding.UTF8.GetBytes("{\"operation\":\"Query\"}");
        string body = await storage.Client.TakeRequestAsync(id, CancellationToken.None);
        Assert.Equal("{\"operation\":\"Query\"}", body);
        Assert.False(storage.Files.ContainsKey(id));
        Assert.Equal(1, storage.Deletes);
    }

    [Fact]
    public async Task OversizedDownloadStillDeletesItsRequestBlob()
    {
        await using var storage = new Storage();
        string id = Guid.NewGuid().ToString("D");
        storage.Files[id] = new byte[Settings.MaxBytes + 1];
        await Assert.ThrowsAsync<InvalidOperationException>(() => storage.Client.TakeRequestAsync(id, CancellationToken.None));
        Assert.False(storage.Files.ContainsKey(id));
        Assert.Equal(1, storage.Deletes);
    }

    [Fact]
    public async Task ShutdownCleanupDeletesOnlyResponsesCreatedByThisAgent()
    {
        await using var storage = new Storage();
        string unrelated = Guid.NewGuid().ToString("D");
        storage.Files[unrelated] = Encoding.UTF8.GetBytes("XUnrelated");
        string id = await storage.Client.PutResponseAsync("{\"rows\":[]}", CancellationToken.None);
        Assert.True(storage.Files.ContainsKey(id));
        await storage.Client.CleanupAsync(false, CancellationToken.None);
        Assert.True(storage.Files.ContainsKey(id));
        await storage.Client.CleanupAsync(true, CancellationToken.None);
        Assert.False(storage.Files.ContainsKey(id));
        Assert.True(storage.Files.ContainsKey(unrelated));
        Assert.Equal(1, storage.Deletes);
    }
}
