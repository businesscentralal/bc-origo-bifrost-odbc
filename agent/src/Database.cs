using System.Data;
using System.Data.Odbc;
using System.Globalization;
using System.Text.Json;

namespace Origo.Bifrost.Odbc.Agent;

public sealed class Database(Settings settings)
{
    public object Execute(Request request, string method)
    {
        request.Validate(method, settings);
        using var connection = new OdbcConnection(settings.Decrypt(request.DbConnectionString, request.ReadOnly));
        connection.Open();
        var identity = connection.GetSchema("DataSourceInformation");
        string dbms = Convert.ToString(identity.Rows[0]["DataSourceProductName"], CultureInfo.InvariantCulture) ?? "";
        string version = Convert.ToString(identity.Rows[0]["DataSourceProductVersion"], CultureInfo.InvariantCulture) ?? "";
        // SQLite's query_only is an engine restriction, independent of the statement checker.
        if (request.ReadOnly)
            ApplyReadOnlyConnectionGuard(connection, dbms, request.TimeoutSeconds);
        if (request.Operation == "TestConnection")
            return new { driverName = connection.Driver, dbmsName = dbms, dbmsVersion = version };
        using var transaction = connection.BeginTransaction();
        if (request.ReadOnly && dbms.Contains("PostgreSQL", StringComparison.OrdinalIgnoreCase))
        {
            using var guard = connection.CreateCommand();
            guard.Transaction = transaction;
            guard.CommandText = "SET TRANSACTION READ ONLY";
            guard.CommandTimeout = request.TimeoutSeconds;
            guard.ExecuteNonQuery();
        }
        if (request.Operation == "GetSchema")
            return GetSchema(connection, request);
        using var command = connection.CreateCommand();
        command.Transaction = transaction;
        command.CommandText = request.Query;
        command.CommandTimeout = request.TimeoutSeconds;
        foreach (var value in request.Parameters)
        {
            var parameter = command.CreateParameter();
            parameter.Value = ParameterValue(value);
            command.Parameters.Add(parameter);
        }
        if (request.Operation == "Execute")
        {
            int affectedRows = command.ExecuteNonQuery();
            transaction.Commit();
            return new { affectedRows = Math.Max(0, affectedRows) };
        }
        using var reader = command.ExecuteReader(CommandBehavior.SingleResult | CommandBehavior.SequentialAccess);
        return ReadRows(reader, request.RowCap);
    }

    public static void ApplyReadOnlyConnectionGuard(OdbcConnection connection, string dbms, int timeoutSeconds)
    {
        if (!dbms.Contains("SQLite", StringComparison.OrdinalIgnoreCase))
            return;
        using var guard = connection.CreateCommand();
        guard.CommandText = "PRAGMA query_only = ON";
        guard.CommandTimeout = timeoutSeconds;
        guard.ExecuteNonQuery();
    }

    public static object ParameterValue(JsonElement value) => value.ValueKind switch
    {
        JsonValueKind.Null => DBNull.Value,
        JsonValueKind.String => value.GetString()!,
        JsonValueKind.True => true,
        JsonValueKind.False => false,
        JsonValueKind.Number when value.TryGetInt64(out var number) => number,
        JsonValueKind.Number => value.GetDecimal(),
        _ => throw new InvalidOperationException("Invalid parameter.")
    };

    public static object ReadRows(IDataReader reader, int cap)
    {
        var columns = Enumerable.Range(0, reader.FieldCount).Select(reader.GetName).ToArray();
        if (columns.Distinct(StringComparer.Ordinal).Count() != columns.Length)
            throw new InvalidOperationException("Column aliases must be unique.");
        using var schema = reader.GetSchemaTable();
        var dateColumns = schema != null && schema.Columns.Contains("ProviderType")
            ? schema.Rows.Cast<DataRow>().Select(column => column["ProviderType"] != DBNull.Value &&
                (OdbcType)Convert.ToInt32(column["ProviderType"], CultureInfo.InvariantCulture) == OdbcType.Date).ToArray()
            : new bool[reader.FieldCount];
        var rows = new List<Dictionary<string, object?>>();
        long bytes = 0;
        while (rows.Count < cap && reader.Read())
        {
            var row = new Dictionary<string, object?>();
            for (int i = 0; i < columns.Length; i++)
            {
                object? value = reader.IsDBNull(i) ? null : reader.GetValue(i);
                // BC JsonValue.AsDate accepts yyyy-MM-dd, while timestamps must retain their time.
                // Use the ODBC provider type: e.g. Oracle DATE can actually be a timestamp.
                if (value is DateTime date && dateColumns[i])
                    value = date.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
                // Binary values remain transportable, while dates/numbers retain JSON types.
                row.Add(columns[i], value);
                bytes += JsonSerializer.SerializeToUtf8Bytes(value, Protocol.Json).Length + columns[i].Length * 6L + 8;
                if (bytes > Settings.MaxBytes / 2)
                    throw new InvalidOperationException("Result exceeds the transport size limit.");
            }
            rows.Add(row);
        }
        bool truncated = reader.Read();
        return new { columns, rows, truncated };
    }

    private static object GetSchema(OdbcConnection connection, Request request)
    {
        using var tables = connection.GetSchema("Tables");
        var objects = new List<object>();
        foreach (DataRow table in tables.Rows)
        {
            string name = Convert.ToString(table["TABLE_NAME"], CultureInfo.InvariantCulture) ?? "";
            if (request.ObjectFilter.Length > 0 && !name.Equals(request.ObjectFilter, StringComparison.OrdinalIgnoreCase))
                continue;
            string? catalog = table["TABLE_CAT"] as string;
            string? schema = table["TABLE_SCHEM"] as string;
            using var columns = connection.GetSchema("Columns", [catalog, schema, name, null]);
            objects.Add(new
            {
                name,
                type = table["TABLE_TYPE"],
                catalog,
                schema,
                columns = columns.Rows.Cast<DataRow>().Take(request.RowCap).Select(column => new
                {
                    name = column["COLUMN_NAME"],
                    type = column["TYPE_NAME"],
                    nullable = Convert.ToInt32(column["NULLABLE"], CultureInfo.InvariantCulture) != 0
                }).ToArray()
            });
            if (objects.Count >= request.RowCap)
                break;
        }
        return new { objects };
    }
}
