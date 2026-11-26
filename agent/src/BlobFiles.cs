using System.Collections.Concurrent;
using System.Text;
using Azure.Storage.Blobs;

namespace Origo.Bifrost.Odbc.Agent;

public interface IBlobFiles
{
    Task<string> TakeRequestAsync(string id, CancellationToken token);
    Task<string> PutResponseAsync(string body, CancellationToken token);
    Task CleanupAsync(bool all, CancellationToken token);
}

public sealed class BlobFiles(BlobContainerClient container) : IBlobFiles
{
    private readonly ConcurrentDictionary<string, DateTimeOffset> pending = new();

    public static void ValidateId(string id)
    {
        if (!Guid.TryParseExact(id, "D", out var guid) || guid.ToString("D") != id)
            throw new InvalidOperationException("Invalid blob identifier.");
    }

    public async Task<string> TakeRequestAsync(string id, CancellationToken token)
    {
        ValidateId(id);
        var blob = container.GetBlobClient(id);
        try
        {
            await using var stream = await blob.OpenReadAsync(cancellationToken: token);
            return await Protocol.ReadBoundedAsync(stream, token);
        }
        finally
        {
            // Delete even on malformed JSON, oversized input or request cancellation.
            using var cleanup = new CancellationTokenSource(TimeSpan.FromSeconds(10));
            await blob.DeleteIfExistsAsync(cancellationToken: cleanup.Token);
        }
    }

    public async Task<string> PutResponseAsync(string body, CancellationToken token)
    {
        string id = Guid.NewGuid().ToString("D");
        pending[id] = DateTimeOffset.UtcNow.AddMinutes(10);
        await using var stream = new MemoryStream(Encoding.UTF8.GetBytes(body));
        await container.GetBlobClient(id).UploadAsync(stream, overwrite: false, cancellationToken: token);
        return id;
    }

    public async Task CleanupAsync(bool all, CancellationToken token)
    {
        foreach (var entry in pending)
        {
            if (!all && entry.Value > DateTimeOffset.UtcNow)
                continue;
            await container.GetBlobClient(entry.Key).DeleteIfExistsAsync(cancellationToken: token);
            pending.TryRemove(entry.Key, out _);
        }
    }
}

public sealed class RequestHandler(IRequestExecutor executor, Settings settings, IBlobFiles? blobs)
{
    public async Task<string> HandleAsync(string body, string method, CancellationToken token)
    {
        var request = Protocol.Parse(body);
        if (request.QueryFileId is { } id)
        {
            if (blobs == null)
                throw new InvalidOperationException("Blob storage is not configured.");
            request = Protocol.Parse(await blobs.TakeRequestAsync(id, token));
        }
        request.Validate(method, settings);
        string response = await executor.ExecuteAsync(request, method, token);
        if (request.ResponseViaBlob)
        {
            if (blobs == null)
                throw new InvalidOperationException("Blob storage is not configured.");
            string responseId = await blobs.PutResponseAsync(response, token);
            return System.Text.Json.JsonSerializer.Serialize(new { queryFileId = responseId }, Protocol.Json);
        }
        return response;
    }
}
