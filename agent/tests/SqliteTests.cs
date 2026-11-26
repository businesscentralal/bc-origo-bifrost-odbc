using System.Data.Odbc;
using System.Text.Json;
using Origo.Bifrost.Odbc.Agent;
using Xunit;

namespace Bifrost.Odbc.Agent.Tests;

// Runs in the worker's own Linux container with the SQLite ODBC driver installed.
public sealed class SqliteTests : IDisposable
{
    private readonly string path = Path.Combine(Path.GetTempPath(), "XBifrostOdbc-" + Guid.NewGuid().ToString("N") + ".db");
    private readonly Settings settings;

    public SqliteTests()
    {
        string driver = Environment.GetEnvironmentVariable("BIFROST_TEST_SQLITE_DRIVER") ?? "SQLite3";
        string connection = $"Driver={{{driver}}};Database={path}";
        settings = PolicyTests.Settings(connection, connection);
        using var database = new OdbcConnection(connection);
        database.Open();
        using var command = database.CreateCommand();
        command.CommandText = "CREATE TABLE XRows (Id INTEGER PRIMARY KEY, Marker TEXT)";
        command.ExecuteNonQuery();
        command.CommandText = "INSERT INTO XRows VALUES (1, 'XFirst'), (2, 'XSecond'), (3, NULL), (4, 'XFourth')";
        command.ExecuteNonQuery();
        command.CommandText = "CREATE TABLE XDates (Day DATE, Stamp TIMESTAMP)";
        command.ExecuteNonQuery();
        command.CommandText = "INSERT INTO XDates VALUES ('2026-11-25', '2026-11-25 10:11:12')";
        command.ExecuteNonQuery();
    }

    [Theory]
    [InlineData("en-US")]
    [InlineData("is-IS")]
    public void NativeDateAndTimestampMatchBcTypedReaderFormats(string culture)
    {
        var previous = System.Globalization.CultureInfo.CurrentCulture;
        var previousUi = System.Globalization.CultureInfo.CurrentUICulture;
        try
        {
            System.Globalization.CultureInfo.CurrentCulture = new(culture);
            System.Globalization.CultureInfo.CurrentUICulture = new(culture);
            using var result = Run(PolicyTests.Request(settings, sql: "SELECT Day, Stamp FROM XDates", parameters: "[]"));
            var row = result.RootElement.GetProperty("rows")[0];
            Assert.Equal("2026-11-25", row.GetProperty("Day").GetString());
            Assert.Equal("2026-11-25T10:11:12", row.GetProperty("Stamp").GetString());
        }
        finally
        {
            System.Globalization.CultureInfo.CurrentCulture = previous;
            System.Globalization.CultureInfo.CurrentUICulture = previousUi;
        }
    }

    [Theory]
    [InlineData("en-US")]
    [InlineData("is-IS")]
    public void RealOdbcQueryUsesPositionalParametersAndReturnsTypedRows(string culture)
    {
        var previous = System.Globalization.CultureInfo.CurrentCulture;
        var previousUi = System.Globalization.CultureInfo.CurrentUICulture;
        try
        {
            System.Globalization.CultureInfo.CurrentCulture = new(culture);
            System.Globalization.CultureInfo.CurrentUICulture = new(culture);
            var request = PolicyTests.Request(settings, sql: "SELECT Id, Marker FROM XRows WHERE Id = ?", parameters: "[2]");
            using var result = Run(request);
            var rows = result.RootElement.GetProperty("rows");
            Assert.Equal(1, rows.GetArrayLength());
            Assert.Equal(2, rows[0].GetProperty("Id").GetInt32());
            Assert.Equal("XSecond", rows[0].GetProperty("Marker").GetString());
        }
        finally
        {
            System.Globalization.CultureInfo.CurrentCulture = previous;
            System.Globalization.CultureInfo.CurrentUICulture = previousUi;
        }
    }

    [Fact]
    public void InjectionParameterIsDataAndCannotChangeRows()
    {
        var request = PolicyTests.Request(settings, sql: "SELECT Id FROM XRows WHERE Marker = ?", parameters: "[\"X' OR 1=1 --\"]");
        using var result = Run(request);
        Assert.Equal(0, result.RootElement.GetProperty("rows").GetArrayLength());
    }

    [Fact]
    public void RealOdbcRowCapIsEnforcedAndFlagged()
    {
        using var result = Run(PolicyTests.Request(settings, sql: "SELECT Id FROM XRows ORDER BY Id", parameters: "[]"));
        Assert.Equal(3, result.RootElement.GetProperty("rows").GetArrayLength());
        Assert.True(result.RootElement.GetProperty("truncated").GetBoolean());
    }

    [Fact]
    public void RealOdbcCatalogAndIdentityMatchStoryB()
    {
        var request = PolicyTests.Request(settings, "TestConnection", "", "[]");
        using var identity = Run(request);
        Assert.Contains("SQLite", identity.RootElement.GetProperty("dbmsName").GetString()!, StringComparison.OrdinalIgnoreCase);
        Assert.NotEmpty(identity.RootElement.GetProperty("dbmsVersion").GetString()!);
        request.Operation = "GetSchema";
        request.ObjectFilter = "XRows";
        using var schema = Run(request);
        var objects = schema.RootElement.GetProperty("objects");
        Assert.Single(objects.EnumerateArray());
        Assert.Equal("XRows", objects[0].GetProperty("name").GetString());
        Assert.Equal(2, objects[0].GetProperty("columns").GetArrayLength());
    }

    [Fact]
    public void DatabaseRejectsWritesWhenStatementCheckerIsBypassed()
    {
        // Deliberately send a write directly to the engine after enabling the same guard as Database.
        using var connection = new OdbcConnection(settings.ReadOnlyConnection);
        connection.Open();
        Database.ApplyReadOnlyConnectionGuard(connection, "SQLite", 2);
        using var command = connection.CreateCommand();
        command.CommandText = "UPDATE XRows SET Marker = 'XUnauthorized' WHERE Id = 1";
        Assert.Throws<OdbcException>(() => command.ExecuteNonQuery());
        command.CommandText = "SELECT Marker FROM XRows WHERE Id = 1";
        Assert.Equal("XFirst", command.ExecuteScalar());
    }

    [Fact]
    public void ExecuteOnlyWritesTheSelfSeededScratchTable()
    {
        var request = PolicyTests.Request(settings, "Execute", "UPDATE XRows SET Marker = ? WHERE Id = ?", "[\"XChanged\",1]");
        request.ReadOnly = false;
        using var result = Run(request, "PUT");
        Assert.Equal(1, result.RootElement.GetProperty("affectedRows").GetInt32());
        using var query = Run(PolicyTests.Request(settings, sql: "SELECT Marker FROM XRows WHERE Id = ?"));
        Assert.Equal("XChanged", query.RootElement.GetProperty("rows")[0].GetProperty("Marker").GetString());
    }

    private JsonDocument Run(Request request, string method = "GET") =>
        JsonDocument.Parse(JsonSerializer.Serialize(new Database(settings).Execute(request, method), Protocol.Json));

    public void Dispose()
    {
        OdbcConnection.ReleaseObjectPool();
        File.Delete(path);
        File.Delete(path + "-journal");
        File.Delete(path + "-wal");
        File.Delete(path + "-shm");
    }
}
