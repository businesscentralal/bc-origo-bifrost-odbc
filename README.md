# Bifröst ODBC

**App name:** Bifrost ODBC
**Publisher:** Origo — **Version:** 28.0.0.0 — **Target:** Cloud (BC 28.0, runtime 17.0)
**App ID:** `a83ef9e7-287e-4a1d-922c-c30686c4fd5d` — **Test app ID:** `9ba2022b-f908-46b7-a42d-312f204d0e15`
**Object ID range:** 10035485–10035534 (tests 98100–98199) — **Namespace:** `Origo.Bifrost.ODBC`

Bifrost ODBC lets an agent read data from any ODBC data source next to the customer's Business Central — SQL Server,
Oracle, MySQL, PostgreSQL, DB2, Access, Excel and others — through the Bifröst local agent and Azure Relay. Business
Central never opens a database connection itself, and agents get read-only access.

**Status:** setup and public AL API implemented. Agent message types and the on-premises agent are tracked under
businesscentralal/bifrost-support#36. The transport uses the JSON wire contract below; the matching agent must implement it.

Foundation discovers this app on **Bifrost Setup** through its application registry. Assign `BIFROST ODBC ori`,
`BIFROST ODBCFull ori` or `BIFROST ODBCRead ori` alongside the appropriate Foundation role. The object allocation is
recorded in [.claude/CLAUDE.md](.claude/CLAUDE.md).

## Public AL API

```al
Parameters.Add(42);
Client.Query('MY-SOURCE', 'select id, name from demo where id = ?', Parameters, Reader);
while Reader.Read() do
    Name := Reader.GetText('name');
```

Use `ODBC Client ori` with a configured source. Parameters keep their array order and never enter the SQL string.
`Query` replaces `ODBC Reader ori`, including on failure. Call `Read()` before a typed getter; check `IsNull()` for SQL NULL.
The reader exposes `GetText`, `GetInteger`, `GetDecimal`, `GetBoolean`, `GetDate`, `GetDateTime`, `GetColumns`,
`RowCount` and `IsTruncated`. Column names are case-sensitive. Dates and date/times use ISO JSON strings.

`Execute(SourceCode, SQL, Parameters)` returns affected rows and refuses a Read Only source before transport.
It is an AL API for PTEs and migration code. `TestConnection(SourceCode, DriverName, DbmsName, DbmsVersion)` returns
three Text outputs. `GetSchema(SourceCode, ObjectFilter, Result)` returns catalog tables/views with nested columns.
All four operations validate source setup, send row cap/timeout and emit one metadata-only `ODBC-0001` telemetry event.
The dimensions are source code, operation, retained query / affected Execute row count, elapsed milliseconds and outcome. SQL,
parameters, connection strings, keys and agent diagnostics never enter this event.

## Agent wire contract

```json
{
  "query": "select id from demo where id = ?",
  "parameters": [42],
  "readOnly": true,
  "rowCap": 10000,
  "timeoutSeconds": 60,
  "dbConnectionString": "<AES-CBC/PKCS7 ciphertext in base64>",
  "operation": "Query"
}
```

The relay receives a JSON body over HTTPS: GET for Query, TestConnection and GetSchema; PUT for Execute.
`ServiceBusAuthorization` carries a short-lived SAS token. Relay namespaces must end in `.servicebus.windows.net`.
Store the AES key and 16-byte AES vector in base64. The connection string stays in company-scoped IsolatedStorage;
only ciphertext goes to the transport. The transport enum defaults to Relay; the test app adds Mock. Other apps can
extend the enum and implement `ODBC Transport ori.Send` without changing the client.

| Operation | Response |
| --- | --- |
| Query | `{"rows":[{"id":42}],"columns":["id"],"truncated":false}` |
| Execute | `{"affectedRows":1}` |
| TestConnection | `{"driverName":"ODBC driver","dbmsName":"DBMS","dbmsVersion":"1.0"}` |
| GetSchema | `{"objects":[{"name":"demo","type":"TABLE","columns":[{"name":"id","type":"INTEGER"}]}]}` |
| Agent error | `{"error":"Agent diagnostic"}` |

GetSchema sends `objectFilter` separately and leaves `query` empty. Query/connection/schema always send `readOnly=true`,
even when the source permits Execute. Both the agent and BC enforce the cap: BC drops excess rows and marks the reader
truncated. Empty query results can retain their column metadata. Agent errors retain the agent diagnostic after stored
credentials and SQL are redacted. Credentials remain `SecretText` through encryption and HTTP content.
Diagnostics up to 256 characters are matched against stored secrets using keyed hash comparisons, without unwrapping
credentials. Oversized diagnostics and residual connection-string fields/URLs return a localized safe fallback. Relay, HTTP, crypto and blob failures return localized diagnostics without raw bodies.

With a blob container configured, the relay receives `responseViaBlob=true`. Bodies above 65,536 characters are staged
under a generated GUID and replaced by `queryFileId` plus operation, readOnly, rowCap and timeoutSeconds. The agent reads
that JSON from the configured container. A response may instead contain `{"queryFileId":"<lowercase GUID without braces>"}`;
BC downloads that JSON from the same container. BC accepts no response URL or arbitrary blob path, and removes temporary
request and response blobs on success or failure. A cleanup failure is reported. No blob or relay call runs in unit tests.
