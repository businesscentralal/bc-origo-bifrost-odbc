# Changelog

All notable changes to Bifrost ODBC are documented here.

## [Unreleased]

### Added
- ODBC.Query.Run staged response (issue #18): optional `output` parameter (`inline` default, `staged`). Staged results are written as one Foundation Blob Staging row (source `ODBC`, `application/json`, file `<source>-<yyyyMMddHHmmss>.json`) with the same `{"columns","rows"}` shape as inline output; the response returns `staged`, `stagingId`, `rowCount`, `columns`, `contentType`, `byteSize` and no `rows`. Inline results above the new source field `Inline Result Limit (KB)` (table 10035493 field 13, default 1024, max 15360; card page 10035498) are staged automatically. Results above the 25 MB staging cap fail with LimitExceeded naming size and limit (handler 10035521; internal test seam event OnGetMaxStagedBytes, used by manual stub test codeunit 98142). Contract parts 10035522 add the parameter, staged response fields, error, a staged example and an Orchestrator playbook workflow (`@10.stagingId`). Tests 98140 StagedOutput, InlineOutput, AutoStage, StagedSizeCap, InvalidOutput and StagingIdIsolation in 1033 and 1039.

## [28.0.0.0] - 2026-11-26

### Fixed
- Preserve URLs, key=value text and long scalar values in successful ODBC message results while removing exact stored secrets. Keep diagnostic filtering separate. Cache driver/DBMS identity with narrowly scoped inherent permission; the read role has no source Modify grant.

### Added
- Bifröst page, Related menu (issue #16): page extension 10035524 adds "Bifrost ODBC Setup" (opens the ODBC Sources page) right after Bifrost Setup; is-IS captions and tooltip; test codeunit 98142 in 1033 and 1039.
- Read-only queued message types (issue #3): ODBC.Source.List, ODBC.Source.Test, ODBC.Schema.Get and ODBC.Query.Run; enum extension 10035516, implementations 10035517–10035520, handler 10035521, bilingual contracts 10035522 and pre-transport SELECT validator 10035523. Queries always request read-only access, preserve positional parameters and enforce a per-call row cap. Source tests cache redacted driver/DBMS identity (source table 10035493, new field 12). Public API overloads retain existing signatures. Tests 98140 and test-only MCP fixture API 98141 use the mock transport in English and Icelandic.
- Read results keep ordinary data (URLs, key=value text, values longer than 256 characters): handler 10035521 now removes only exact stored secrets from cells, column names, catalogue text and source identity through the new `ODBC Secret Mgt ori.RedactValue` (codeunit 10035501); diagnostics keep the stricter Redact rules. The Read role keeps `R` on ODBC Source (table 10035493); the handler caches the Source.Test identity through InherentPermissions instead of a direct Modify grant. Tests 98140 DataPreserved and ReadRoleSourceTest in 1033 and 1039.
- Public ODBC AL API (issue #2): Query, Execute, TestConnection and GetSchema in client 10035506; capped, typed row cursor in reader 10035507; extensible transport interface/enum 10035508 with relay 10035509 and blob staging/cleanup 10035510. Parameters remain positional, reads always request read-only access, Execute refuses read-only sources, and one metadata-only telemetry event is emitted per call. SecretText-safe encryption, transport and bounded diagnostic redaction. Mock-only bilingual API tests use objects 98120–98122.
- ODBC setup (story #1): relay connections (table 10035491, pages 10035494/10035495), blob containers (table 10035492, pages 10035496/10035497), ODBC sources (table 10035493, pages 10035498/10035499) with Read Only default true, Row Cap 10 000 and Timeout 60; secrets (SAS key, blob secret, connection string/DSN, AES key) in IsolatedStorage only via enum 10035504, codeunit 10035501 and dialog page 10035503; `ValidateSetup` (codeunit 10035502); blob auth type enum 10035500; BIFROST ODBCRead/ODBCFull ori now grant the setup tables and pages; tests 98102.
- Repository scaffold: app registration with Bifröst Foundation, Bifrost ODBC permission sets wired into the Foundation Full and Read roles, AL-Go CI/CD and source guards (epic businesscentralal/bifrost-support#36).
