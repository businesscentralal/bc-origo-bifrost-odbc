using System.Text.Json;
using System.Text.Json.Serialization;

namespace Origo.Bifrost.Odbc.Agent;

public sealed class Request
{
    public string Operation { get; set; } = "";
    public string Query { get; set; } = "";
    public string DbConnectionString { get; set; } = "";
    public JsonElement[] Parameters { get; set; } = [];
    public bool ReadOnly { get; set; } = true;
    public int RowCap { get; set; } = 10000;
    public int TimeoutSeconds { get; set; } = 60;
    public string ObjectFilter { get; set; } = "";
    public string? QueryFileId { get; set; }
    public bool ResponseViaBlob { get; set; }

    public void Validate(string method, Settings settings)
    {
        if (RowCap < 1 || TimeoutSeconds < 1 || Parameters.Length > 1024 ||
            DbConnectionString.Length == 0 || QueryFileId != null)
            throw new InvalidOperationException("Invalid request.");
        if (Operation is not ("Query" or "Execute" or "GetSchema" or "TestConnection"))
            throw new InvalidOperationException("Unknown operation.");
        if (Operation == "Execute" ? method != "PUT" || ReadOnly : method != "GET" || !ReadOnly)
            throw new InvalidOperationException("Invalid method or read-only policy.");
        RowCap = Math.Min(RowCap, settings.MaxRows);
        TimeoutSeconds = Math.Min(TimeoutSeconds, settings.MaxSeconds);
        if (Operation is "Query" or "Execute")
            SqlPolicy.Validate(Query, Parameters.Length, ReadOnly);
        else if (Parameters.Length != 0)
            throw new InvalidOperationException("Unexpected parameters.");
        foreach (var parameter in Parameters)
            if (parameter.ValueKind is JsonValueKind.Array or JsonValueKind.Object or JsonValueKind.Undefined)
                throw new InvalidOperationException("Parameters must be scalar values.");
    }
}

public static class Protocol
{
    public const string Failure = "{\"error\":\"The ODBC agent request failed. Check the agent configuration and request.\"}";
    public static readonly JsonSerializerOptions Json = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        UnmappedMemberHandling = JsonUnmappedMemberHandling.Disallow,
        MaxDepth = 32
    };

    public static Request Parse(string body) => JsonSerializer.Deserialize<Request>(body, Json) ??
        throw new InvalidOperationException("Missing request.");

    public static async Task<string> ReadBoundedAsync(Stream stream, CancellationToken token)
    {
        using var buffer = new MemoryStream();
        var chunk = new byte[8192];
        int length;
        while ((length = await stream.ReadAsync(chunk, token)) != 0)
        {
            if (buffer.Length + length > Settings.MaxBytes)
                throw new InvalidOperationException("Payload is too large.");
            await buffer.WriteAsync(chunk.AsMemory(0, length), token);
        }
        return System.Text.Encoding.UTF8.GetString(buffer.GetBuffer(), 0, (int)buffer.Length);
    }
}
