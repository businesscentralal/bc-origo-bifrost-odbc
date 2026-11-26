# Install the Bifröst ODBC agent

The agent is a .NET 8 Windows service. It opens an outbound Azure Relay hybrid connection and uses `System.Data.Odbc.OdbcConnection` with the local driver manager. Business Central never opens the database connection. The service supports the public AL API from story B: Query, Execute (AL only), TestConnection and GetSchema. There is no write message type for agents.

## Prerequisites

- Windows x64, a matching 64-bit ODBC driver and a database reachable from the service machine. The published Windows bundle includes the .NET runtime. A DSN must be a **64-bit System DSN**; a user DSN is not visible to a service account. Check it with the 64-bit ODBC Data Source Administrator.
- An Azure Relay hybrid connection with separate Send credentials for BC and Listen credentials for the service. Only outbound TLS/WebSocket traffic on port 443 is required. Do not open an inbound port.
- A dedicated least-privilege Windows service identity and a database identity with SELECT/catalog permissions only. Do not run as an administrator, database owner, `sysadmin`, `db_owner`, or an account that can execute write-capable procedures. For trusted SQL Server authentication, the service's Windows identity is the database identity; an interactive administrator's successful test does not prove service access.
- An approved **signed CI artifact**. Verify the Authenticode status and expected organization publisher on `Bifrost.Odbc.Agent.exe` and `Bifrost.Odbc.Agent.dll`, and check the artifact's SHA-256. Do not install a local unsigned developer build as a release.

## Protect configuration and exchange the AES key

Provision the following environment variables through your approved secret deployment mechanism, under the service identity. Do not put real values in scripts, shell history, tickets, command lines, screenshots or source control. Use a service-specific environment block with registry access restricted to administrators, SYSTEM and the service identity; do not expose these as machine-wide variables. Disable process dumps and diagnostic tracing that could capture process memory or network bodies. The agent does not log request bodies, SQL, parameter values, connection strings, keys or raw driver errors.

| Variable | Purpose |
| --- | --- |
| `BIFROST_ODBC_RELAY_CONNECTION` | Relay connection configuration with Listen permission and an EntityPath. |
| `BIFROST_ODBC_AES_KEY` | Base64-encoded 16/24/32-byte AES key, matching the source's protected AES key in BC. |
| `BIFROST_ODBC_AES_VECTOR` | Base64-encoded 16-byte vector, matching the source's AES Vector in BC. |
| `BIFROST_ODBC_READ_CONNECTION` | Exact ODBC DSN/driver connection string allowed for read operations. Its database identity **must be read-only**. |
| `BIFROST_ODBC_WRITE_CONNECTION` | Optional, separate connection for the public AL Execute API. Omit to disable Execute. Never give its database identity to the read connection. |
| `BIFROST_ODBC_BLOB_CONNECTION` | Optional storage configuration, restricted to a dedicated temporary container. |
| `BIFROST_ODBC_BLOB_CONTAINER` | Required when Blob is configured; must match BC's selected container. |

Exchange a newly generated key through an approved secret channel. Store it in BC through **Set AES key**, and set the matching vector. Set the connection through **Set connection string**. Ciphertext is AES-CBC with PKCS7 padding over UTF-8 bytes, compatible with BC's Rijndael provider. CBC does not authenticate the payload: Relay authorization and TLS are required; never expose the worker subprocess as a public endpoint. Dedicate a listener and AES key to one source/security boundary. Rotate both sides together.

The decrypted connection must match the configured connection **exactly**. This pins the destination and identity; a request cannot substitute another DSN, database or a writable identity. Configure additional independent service instances for additional sources. A connection string is never accepted merely because it can be decrypted.

## Database protection

SQL filtering is an additional restriction. It does not prove a query is side-effect free. Database permissions remain mandatory, including for a user-defined function or a driver-specific escape from the statement checker.

- **SQL Server:** install ODBC Driver 18 for SQL Server. Use trusted authentication under a dedicated service identity, with SELECT only on the intended objects and enough catalog visibility. Do not grant database/schema write, DDL, impersonation, ownership, or EXECUTE permissions. `ApplicationIntent=ReadOnly` is routing metadata and is **not** a security boundary. SQL Server has no general read-only transaction setting, so the database user's permissions are the protection. Before production, prove with that identity that a direct INSERT/UPDATE/DELETE and CREATE TABLE fails, independently of the agent checker. Use only an administrator-created scratch table for this check. Never test writes against business tables.
- **PostgreSQL:** use a SELECT-only login; read requests additionally start a `SET TRANSACTION READ ONLY` transaction. Do not grant write-capable or security-definer routines.
- **SQLite:** use a dedicated database file and restricted OS access. Each read connection enables `PRAGMA query_only = ON` before catalog/query work. Tests deliberately bypass the SQL checker and verify the engine rejects UPDATE and leaves the fixture unchanged. Do not use the optional write connection in a read-only deployment.
- **Other ODBC drivers:** install the driver's read-only configuration and a database/file identity that cannot modify data. Validate it independently before use. The driver manager does not offer a universal enforceable read-only transaction. If that source cannot enforce read-only access, do not deploy it as a read source.

On the worker test host only, the SQL Server endpoint is `localhost`, the connection is trusted, and the database is the worker's own tenant id (issue #9). This is host-local from the agent's perspective. The test runner creates and drops only its own scratch table; it never changes BC tables. That end-to-end setup belongs to issue #5 after the agent and message types merge.

## Install and operate

1. Extract the verified signed bundle into an administrator-writable installation directory. Give the service identity read/execute access, not write access to binaries. Provision the protected service environment first.
2. Register the service with the Windows Service Control Manager, using a dedicated virtual or managed service account. For a virtual account, an administrator can use the following placeholder paths (no credentials on the command line):

   ```powershell
   sc.exe create BifrostODBC binPath= '"C:\Program Files\Bifrost ODBC\Bifrost.Odbc.Agent.exe"' start= auto obj= 'NT SERVICE\BifrostODBC'
   sc.exe failure BifrostODBC reset= 86400 actions= restart/5000/restart/30000
   sc.exe start BifrostODBC
   ```

3. In BC, configure the same relay, Blob container (if used), AES key/vector and exact ODBC connection. Keep **Read Only** enabled. **Test connection** calls the real ODBC connection through Relay and returns driver, DBMS name and DBMS version; GetSchema uses ODBC catalog functions. There is no unauthenticated health port. For a developer console run, execute the same agent binary under its protected test environment.
4. Test a parameterized SELECT against self-seeded data; verify row caps and a failed direct write under the read identity. Repeat through the BC API/message types in English (1033) and Icelandic (1039). A successful setup validation alone does not test the transport or database.
5. Stop the service before rotating configuration or replacing binaries. Keep the prior verified bundle for rollback. Remove temporary BC records and Blob files after tests, then remove the service if it was test-only.

Limits are enforced in the agent: at most 10,000 returned rows, 60 seconds per request, 1,024 scalar positional parameters, 8 MiB input/output, and four concurrent workers. Request limits may lower these values; they cannot raise them. Query SQL must be a single SELECT or read-only WITH, with `?` placeholders. Named parameters, statement separators, comments and write tokens are rejected outside SQL quotes. Values are bound with `OdbcParameter`, never interpolated. Use column aliases when names would be duplicated. Large individual values can exceed the response bound and fail rather than return an incomplete value.

Every request executes in a separate process. The supervisor kills it at its deadline, bounding drivers that ignore command timeout or block on login/catalog calls. Read transactions are disposed without commit. A timed-out **Execute** has an indeterminate outcome: a database may already have committed; inspect the scratch/application state before retrying. Do not automatically retry writes.

## Blob protocol and cleanup

The story-B JSON envelope uses `operation`, `query`, `parameters`, `readOnly`, `rowCap`, `timeoutSeconds`, `objectFilter`, `dbConnectionString`, optional `queryFileId` and `responseViaBlob`. GET handles Query/GetSchema/TestConnection; PUT handles Execute only with `readOnly=false` and the separately configured write connection. Health returns `driverName`, `dbmsName`, `dbmsVersion`; Query returns `columns`, typed `rows` and `truncated`; GetSchema returns `objects`; Execute returns `affectedRows`.

Only canonical lower-case GUID Blob names are accepted, never paths or URLs. The agent deletes request files after reading, including on malformed/oversized payload failure. BC deletes its temporary request and response files in its cleanup path. The agent also deletes its response files after ten minutes or on clean shutdown if a caller fails to clean up. Configure a short storage lifecycle expiration on the dedicated container as recovery from machine/process crashes. Do not share the temporary container with customer documents. A failed cleanup is reported, never treated as success.

The legacy Data Migration service is `LocalSQLAgent` / `LocalRelaySQLAgent` (.NET 8, `SqlConnection`, SQL Server only). It uses GET/PUT, AES-encrypted `dbConnectionString`, and prefixed Blob files `request-<guid>` / `response-<guid>` with `queryResult` / `nonQueryResult`. This service preserves the transport pattern but follows the merged Bifröst story-B JSON contract and GUID-only Blob names; it is **not a drop-in replacement for the legacy AL client**. The prerequisite finding is recorded on epic #36.

## Build, test and sign

Developers need .NET SDK 8 and an installed SQLite ODBC driver. On Linux, `BIFROST_TEST_SQLITE_DRIVER` may name the SQLite ODBC shared-library path. Run `agent/Build-Agent.ps1`; it runs every agent test and publishes the self-contained Windows folder. A missing driver fails the run. Linux test fixtures use unique temporary database files and remove them, including journal/WAL files.

The Architect must wire a separate agent job into the organization's existing signing path: build/test this directory, publish `win-x64`, Authenticode-sign the agent EXE and DLL with the existing protected organization signer, and run `agent/Package-SignedAgent.ps1` before uploading the archive, commit SHA, checksums and TRX results. The packaging script refuses unsigned or invalid signatures. It never accesses a private key. A local cross-published Windows bundle proves compilation, not Windows service installation or CI signing. AC05 remains pending until the signed artifact exists.
