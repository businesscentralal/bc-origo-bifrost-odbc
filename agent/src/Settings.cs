using System.Security.Cryptography;
using System.Text;

namespace Origo.Bifrost.Odbc.Agent;

// Deliberately not a record: ToString must never expand configuration secrets.
public sealed class Settings
{
    public required byte[] AesKey { get; init; }
    public required byte[] AesVector { get; init; }
    public required string ReadOnlyConnection { get; init; }
    public string? WriteConnection { get; init; }
    public int MaxRows { get; init; } = 10000;
    public int MaxSeconds { get; init; } = 60;
    public const int MaxBytes = 8 * 1024 * 1024;

    public static Settings FromEnvironment() => new()
    {
        AesKey = Convert.FromBase64String(Required("BIFROST_ODBC_AES_KEY")),
        AesVector = Convert.FromBase64String(Required("BIFROST_ODBC_AES_VECTOR")),
        ReadOnlyConnection = Required("BIFROST_ODBC_READ_CONNECTION"),
        WriteConnection = Environment.GetEnvironmentVariable("BIFROST_ODBC_WRITE_CONNECTION")
    };

    public static string Required(string name) =>
        Environment.GetEnvironmentVariable(name) is { Length: > 0 } value ? value :
            throw new InvalidOperationException("Agent configuration is incomplete.");

    public string Decrypt(string encrypted, bool readOnly)
    {
        using var aes = Aes.Create();
        aes.Key = AesKey;
        aes.IV = AesVector;
        aes.Mode = CipherMode.CBC;
        aes.Padding = PaddingMode.PKCS7;
        var cipher = Convert.FromBase64String(encrypted);
        var bytes = aes.DecryptCbc(cipher, AesVector, PaddingMode.PKCS7);
        try
        {
            var connection = new UTF8Encoding(false, true).GetString(bytes);
            var suppliedHash = SHA256.HashData(Encoding.UTF8.GetBytes(connection));
            bool Matches(string? allowed) => !string.IsNullOrEmpty(allowed) &&
                CryptographicOperations.FixedTimeEquals(suppliedHash, SHA256.HashData(Encoding.UTF8.GetBytes(allowed)));
            bool readMatches = Matches(ReadOnlyConnection);
            bool writeMatches = Matches(WriteConnection);
            // A writable AL source still supports Query/TestConnection/GetSchema, but its
            // reads must never open the writable credential carried in its encrypted payload.
            if (readOnly && (readMatches || writeMatches))
                return ReadOnlyConnection;
            if (!readOnly && writeMatches)
                return WriteConnection!;
            throw new InvalidOperationException("Connection is not permitted.");
        }
        finally
        {
            CryptographicOperations.ZeroMemory(bytes);
        }
    }
}
