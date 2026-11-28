using System.Text.Json;
using Origo.Bifrost.Odbc.Agent;
using Xunit;

namespace Bifrost.Odbc.Agent.Tests;

public sealed class TransportTests
{
    private sealed class Executor : IRequestExecutor
    {
        public string? Operation { get; private set; }
        public Task<string> ExecuteAsync(Request request, string method, CancellationToken cancellationToken)
        {
            Operation = request.Operation;
            return Task.FromResult("{\"columns\":[],\"rows\":[],\"truncated\":false}");
        }
    }

    private sealed class Files(string requestBody) : IBlobFiles
    {
        public string? Taken { get; private set; }
        public string? Stored { get; private set; }
        public Task<string> TakeRequestAsync(string id, CancellationToken token)
        {
            BlobFiles.ValidateId(id);
            Taken = id;
            return Task.FromResult(requestBody);
        }
        public Task<string> PutResponseAsync(string body, CancellationToken token)
        {
            Stored = body;
            return Task.FromResult("aaaaaaaa-0000-0000-0000-000000000000");
        }
        public Task CleanupAsync(bool all, CancellationToken token) => Task.CompletedTask;
    }

    [Fact]
    public async Task StagedRequestReturnsGuidResponseEnvelope()
    {
        var settings = PolicyTests.Settings();
        var request = PolicyTests.Request(settings);
        request.ResponseViaBlob = true;
        var files = new Files(JsonSerializer.Serialize(request, Protocol.Json));
        var executor = new Executor();
        var handler = new RequestHandler(executor, settings, files);
        string body = await handler.HandleAsync("{\"queryFileId\":\"aaaaaaaa-0000-0000-0000-000000000000\"}", "GET", CancellationToken.None);
        Assert.Equal("Query", executor.Operation);
        Assert.Equal("aaaaaaaa-0000-0000-0000-000000000000", files.Taken);
        Assert.Contains("\"rows\":[]", files.Stored!);
        Assert.Equal("{\"queryFileId\":\"aaaaaaaa-0000-0000-0000-000000000000\"}", body);
    }

    [Fact]
    public async Task NestedBlobReferencesAreRejected()
    {
        var settings = PolicyTests.Settings();
        var request = PolicyTests.Request(settings);
        request.QueryFileId = "aaaaaaaa-0000-0000-0000-000000000000";
        var files = new Files(JsonSerializer.Serialize(request, Protocol.Json));
        var executor = new Executor();
        var handler = new RequestHandler(executor, settings, files);
        await Assert.ThrowsAsync<InvalidOperationException>(() => handler.HandleAsync("{\"queryFileId\":\"aaaaaaaa-0000-0000-0000-000000000000\"}", "GET", CancellationToken.None));
        Assert.Null(executor.Operation);
    }

    [Fact]
    public async Task BlobReferenceWithoutConfiguredStorageIsRejected()
    {
        var settings = PolicyTests.Settings();
        var handler = new RequestHandler(new Executor(), settings, null);
        await Assert.ThrowsAsync<InvalidOperationException>(() => handler.HandleAsync("{\"queryFileId\":\"aaaaaaaa-0000-0000-0000-000000000000\"}", "GET", CancellationToken.None));
    }

    [Fact]
    public async Task StagedRequestCannotChangeHttpMethodPolicy()
    {
        var settings = PolicyTests.Settings();
        var request = PolicyTests.Request(settings, "Execute", "UPDATE XRows SET Marker = ?");
        request.ReadOnly = false;
        var executor = new Executor();
        var handler = new RequestHandler(executor, settings, new Files(JsonSerializer.Serialize(request, Protocol.Json)));
        await Assert.ThrowsAsync<InvalidOperationException>(() => handler.HandleAsync("{\"queryFileId\":\"aaaaaaaa-0000-0000-0000-000000000000\"}", "GET", CancellationToken.None));
        Assert.Null(executor.Operation);
    }
}
