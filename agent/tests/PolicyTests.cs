using System.Data;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Origo.Bifrost.Odbc.Agent;
using Xunit;

namespace Bifrost.Odbc.Agent.Tests;

public sealed class PolicyTests
{
    internal static Settings Settings(string readConnection = "Driver={Unit only};Database=XFixture", string? writeConnection = null) => new()
    {
        AesKey = SHA256.HashData(Encoding.UTF8.GetBytes("X-unit-only-key")),
        AesVector = Encoding.UTF8.GetBytes("X-unit-only-iv!!"),
        ReadOnlyConnection = readConnection,
        WriteConnection = writeConnection,
        MaxRows = 3,
        MaxSeconds = 2
    };

    internal static string Encrypt(Settings settings, string connection)
    {
        using var aes = Aes.Create();
        aes.Key = settings.AesKey;
        return Convert.ToBase64String(aes.EncryptCbc(Encoding.UTF8.GetBytes(connection), settings.AesVector, PaddingMode.PKCS7));
    }

    internal static Request Request(Settings settings, string operation = "Query", string sql = "SELECT ? AS XMarker", string parameters = "[1]") => new()
    {
        Operation = operation,
        Query = sql,
        Parameters = JsonSerializer.Deserialize<JsonElement[]>(parameters)!,
        DbConnectionString = Encrypt(settings, settings.ReadOnlyConnection)
    };

    [Theory]
    [InlineData("SELECT ? AS XMarker", 1)]
    [InlineData("SELECT '?' AS XMarker", 0)]
    [InlineData("SELECT 'it''s ?; DROP' AS XMarker", 0)]
    [InlineData("SELECT [delete], \"update\", `insert` FROM XTable WHERE Id = ?", 1)]
    [InlineData("WITH XRows AS (SELECT ? AS XId) SELECT XId FROM XRows", 1)]
    public void AcceptsSingleParameterizedRead(string sql, int count) => SqlPolicy.Validate(sql, count, true);

    [Theory]
    [InlineData("DELETE FROM XRows", 0)]
    [InlineData("SELECT * INTO XCopy FROM XRows", 0)]
    [InlineData("SELECT 1; DELETE FROM XRows", 0)]
    [InlineData("WITH X AS (DELETE FROM XRows RETURNING *) SELECT * FROM X", 0)]
    [InlineData("SELECT 1 -- injected", 0)]
    [InlineData("SELECT 1 /* comment */", 0)]
    [InlineData("SELECT 1 # comment", 0)]
    [InlineData("SELECT :name", 0)]
    [InlineData("SELECT @name", 0)]
    [InlineData("SELECT $1", 0)]
    [InlineData("SELECT ?", 0)]
    [InlineData("SELECT 1", 1)]
    [InlineData("SELECT 'unterminated", 0)]
    [InlineData("SELECT 'a\\'b'", 0)]
    [InlineData("", 0)]
    public void RefusesUnsafeSqlOrParameterMismatch(string sql, int count) =>
        Assert.Throws<InvalidOperationException>(() => SqlPolicy.Validate(sql, count, true));

    [Fact]
    public void ClampsLimitsToServerCaps()
    {
        var settings = Settings();
        var request = Request(settings);
        request.Validate("GET", settings);
        Assert.Equal(3, request.RowCap);
        Assert.Equal(2, request.TimeoutSeconds);
    }

    [Theory]
    [InlineData(0, 1)]
    [InlineData(1, 0)]
    [InlineData(-1, 1)]
    [InlineData(1, -1)]
    public void RefusesInvalidLimits(int rows, int seconds)
    {
        var settings = Settings();
        var request = Request(settings);
        request.RowCap = rows;
        request.TimeoutSeconds = seconds;
        Assert.Throws<InvalidOperationException>(() => request.Validate("GET", settings));
    }

    [Fact]
    public void AcceptsExactMinimumLimits()
    {
        var settings = Settings();
        var request = Request(settings);
        request.RowCap = 1;
        request.TimeoutSeconds = 1;
        request.Validate("GET", settings);
        Assert.Equal(1, request.RowCap);
        Assert.Equal(1, request.TimeoutSeconds);
    }

    [Theory]
    [InlineData("Query", "PUT", true)]
    [InlineData("Query", "GET", false)]
    [InlineData("Execute", "GET", false)]
    [InlineData("Execute", "PUT", true)]
    [InlineData("TestConnection", "GET", false)]
    [InlineData("Unexpected", "GET", true)]
    public void RefusesMethodAndReadOnlyDowngrades(string operation, string method, bool readOnly)
    {
        var settings = Settings();
        var request = Request(settings, operation);
        request.ReadOnly = readOnly;
        Assert.Throws<InvalidOperationException>(() => request.Validate(method, settings));
    }

    [Fact]
    public void AesRoundTripAndSeparateConnectionPolicies()
    {
        var settings = Settings(writeConnection: "Driver={Unit only};Database=XWriteFixture");
        Assert.Equal(settings.ReadOnlyConnection, settings.Decrypt(Encrypt(settings, settings.ReadOnlyConnection), true));
        Assert.Equal(settings.WriteConnection, settings.Decrypt(Encrypt(settings, settings.WriteConnection!), false));
        Assert.Equal(settings.ReadOnlyConnection, settings.Decrypt(Encrypt(settings, settings.WriteConnection!), true));
        Assert.Throws<InvalidOperationException>(() => settings.Decrypt(Encrypt(settings, settings.ReadOnlyConnection), false));
    }

    [Fact]
    public void UnconfiguredDestinationCannotUseEitherConnectionPolicy()
    {
        var settings = Settings(writeConnection: "Driver={Unit only};Database=XWriteFixture");
        string encrypted = Encrypt(settings, "Driver={Unit only};Database=XUnconfiguredFixture");
        Assert.Throws<InvalidOperationException>(() => settings.Decrypt(encrypted, true));
        Assert.Throws<InvalidOperationException>(() => settings.Decrypt(encrypted, false));
    }

    [Theory]
    [InlineData("Driver={XFixture};Database=XTest", "9j1leCfGlLUdYGV4MkTmt65ql1FjaTq1DXLaeCkW1TirGQG16KRkOeFvSywOevlJ")]
    [InlineData("Driver={XPrófun};Database=XGögn", "Ko+wQBf8p664txT2BRD/9CUGCx43hxvFA4iGj0mTewn/LrVDjbSeN6asq7BdpIPd")]
    public void MatchesFixedVectorsAlsoVerifiedByBcRijndaelProvider(string plain, string cipher)
    {
        var settings = new Settings
        {
            AesKey = Convert.FromBase64String("MDEyMzQ1Njc4OWFiY2RlZg=="),
            AesVector = Convert.FromBase64String("ZmVkY2JhOTg3NjU0MzIxMA=="),
            ReadOnlyConnection = plain
        };
        Assert.Equal(plain, settings.Decrypt(cipher, true));
        Assert.Equal(cipher, Encrypt(settings, plain));
    }

    [Fact]
    public void ExecuteIsDisabledUnlessAWriteConnectionIsConfigured()
    {
        var settings = Settings();
        Assert.Throws<InvalidOperationException>(() => settings.Decrypt(Encrypt(settings, settings.ReadOnlyConnection), false));
    }

    [Fact]
    public void InvalidCiphertextDoesNotReturnItsContents()
    {
        var settings = Settings();
        Assert.Throws<FormatException>(() => settings.Decrypt("X-invalid-ciphertext", true));
        Assert.DoesNotContain("Connection", settings.ToString()!);
    }

    [Theory]
    [InlineData("{}")]
    [InlineData("[]")]
    public void RejectsNonScalarParameters(string parameter)
    {
        var settings = Settings();
        var request = Request(settings, parameters: "[" + parameter + "]");
        Assert.Throws<InvalidOperationException>(() => request.Validate("GET", settings));
    }

    [Theory]
    [InlineData("null")]
    [InlineData("true")]
    [InlineData("false")]
    [InlineData("1")]
    [InlineData("1.25")]
    [InlineData("\"X' OR 1=1 --\"")]
    public void AcceptsTypedScalarParameters(string parameter)
    {
        using var json = JsonDocument.Parse(parameter);
        object value = Database.ParameterValue(json.RootElement);
        Assert.NotNull(value);
        if (json.RootElement.ValueKind == JsonValueKind.String)
            Assert.Equal("X' OR 1=1 --", value);
    }

    [Theory]
    [InlineData(0, 3, false)]
    [InlineData(2, 3, false)]
    [InlineData(3, 3, false)]
    [InlineData(4, 3, true)]
    public void RowCapIncludesEmptyResultsAndExactBoundary(int count, int cap, bool truncated)
    {
        using var table = new DataTable();
        table.Columns.Add("XId", typeof(int));
        table.Columns.Add("XMarker", typeof(string));
        for (int i = 0; i < count; i++)
            table.Rows.Add(i, i == 0 ? DBNull.Value : "XMarker");
        using var reader = table.CreateDataReader();
        using var result = JsonDocument.Parse(JsonSerializer.Serialize(Database.ReadRows(reader, cap), Protocol.Json));
        Assert.Equal(Math.Min(count, cap), result.RootElement.GetProperty("rows").GetArrayLength());
        Assert.Equal(truncated, result.RootElement.GetProperty("truncated").GetBoolean());
        Assert.Equal(2, result.RootElement.GetProperty("columns").GetArrayLength());
    }

    [Theory]
    [InlineData("../XBlob")]
    [InlineData("request-00000000-0000-0000-0000-000000000000")]
    [InlineData("https://example.invalid/blob")]
    [InlineData("{00000000-0000-0000-0000-000000000000}")]
    [InlineData("AAAAAAAA-0000-0000-0000-000000000000")]
    public void BlobIdentifiersCannotSelectPathsOrLegacyPrefixes(string id) =>
        Assert.Throws<InvalidOperationException>(() => BlobFiles.ValidateId(id));

    [Fact]
    public void CanonicalBlobIdentifierIsAccepted() => BlobFiles.ValidateId("aaaaaaaa-0000-0000-0000-000000000000");

    [Fact]
    public async Task RejectsOversizedRequestBeforeParsing()
    {
        await using var stream = new MemoryStream(new byte[SettingsMaxBytesPlusOne]);
        await Assert.ThrowsAsync<InvalidOperationException>(() => Protocol.ReadBoundedAsync(stream, CancellationToken.None));
    }

    private const int SettingsMaxBytesPlusOne = Origo.Bifrost.Odbc.Agent.Settings.MaxBytes + 1;
}
