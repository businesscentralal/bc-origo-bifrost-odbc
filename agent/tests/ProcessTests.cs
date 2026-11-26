using System.Diagnostics;
using System.Text.Json;
using Origo.Bifrost.Odbc.Agent;
using Xunit;

[assembly: CollectionBehavior(DisableTestParallelization = true)]

namespace Bifrost.Odbc.Agent.Tests;

public sealed class ProcessTests
{
    private static async Task WithEnvironmentAsync(Func<Settings, Task> test)
    {
        string path = Path.Combine(Path.GetTempPath(), "XBifrostWorker-" + Guid.NewGuid().ToString("N") + ".db");
        string driver = Environment.GetEnvironmentVariable("BIFROST_TEST_SQLITE_DRIVER") ?? "SQLite3";
        var settings = PolicyTests.Settings($"Driver={{{driver}}};Database={path}");
        var values = new Dictionary<string, string>
        {
            ["BIFROST_ODBC_AES_KEY"] = Convert.ToBase64String(settings.AesKey),
            ["BIFROST_ODBC_AES_VECTOR"] = Convert.ToBase64String(settings.AesVector),
            ["BIFROST_ODBC_READ_CONNECTION"] = settings.ReadOnlyConnection
        };
        var original = values.Keys.ToDictionary(key => key, Environment.GetEnvironmentVariable);
        try
        {
            foreach (var entry in values)
                Environment.SetEnvironmentVariable(entry.Key, entry.Value);
            await test(settings);
        }
        finally
        {
            foreach (var entry in original)
                Environment.SetEnvironmentVariable(entry.Key, entry.Value);
            System.Data.Odbc.OdbcConnection.ReleaseObjectPool();
            File.Delete(path);
            File.Delete(path + "-journal");
        }
    }

    [Fact]
    public Task ChildProcessRunsRealParameterizedOdbc() => WithEnvironmentAsync(async settings =>
    {
        var request = PolicyTests.Request(settings);
        var executor = new RequestExecutor(settings);
        using var response = JsonDocument.Parse(await executor.ExecuteAsync(request, "GET", CancellationToken.None));
        Assert.Equal(1, response.RootElement.GetProperty("rows")[0].GetProperty("XMarker").GetInt32());
    });

    [Fact]
    public Task HardDeadlineKillsADriverThatKeepsComputing() => WithEnvironmentAsync(async settings =>
    {
        var request = PolicyTests.Request(settings, sql:
            "WITH RECURSIVE XRows(XId) AS (SELECT 1 UNION ALL SELECT XId + 1 FROM XRows WHERE XId < 1000000000) SELECT SUM(XId) AS XSum FROM XRows",
            parameters: "[]");
        request.TimeoutSeconds = 1;
        var started = Stopwatch.StartNew();
        await Assert.ThrowsAnyAsync<OperationCanceledException>(() => new RequestExecutor(settings).ExecuteAsync(request, "GET", CancellationToken.None));
        Assert.InRange(started.Elapsed.TotalSeconds, 0.5, 10);
    });

    [Theory]
    [InlineData(true)]
    [InlineData(false)]
    public Task RawCipherAndSqlAreAbsentFromChildFailure(bool invalidCipher) => WithEnvironmentAsync(async settings =>
    {
        var request = PolicyTests.Request(settings, sql: "SELECT XPrivateMarker FROM XMissingTable", parameters: "[]");
        if (invalidCipher)
            request.DbConnectionString = "X-private-invalid-cipher";
        string response = await new RequestExecutor(settings).ExecuteAsync(request, "GET", CancellationToken.None);
        Assert.Equal(Protocol.Failure, response);
        Assert.DoesNotContain("XPrivateMarker", response);
        Assert.DoesNotContain("X-private", response);
    });
}
