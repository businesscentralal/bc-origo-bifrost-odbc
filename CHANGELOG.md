# Changelog

All notable changes to Bifrost ODBC are documented here.

## [Unreleased]

### Added
- ODBC setup (story #1): relay connections (table 10035491, pages 10035494/10035495), blob containers (table 10035492, pages 10035496/10035497), ODBC sources (table 10035493, pages 10035498/10035499) with Read Only default true, Row Cap 10 000 and Timeout 60; secrets (SAS key, blob secret, connection string/DSN, AES key) in IsolatedStorage only via enum 10035504, codeunit 10035501 and dialog page 10035503; `ValidateSetup` (codeunit 10035502); blob auth type enum 10035500; BIFROST ODBCRead/ODBCFull ori now grant the setup tables and pages; tests 98102.
- Repository scaffold: app registration with Bifröst Foundation, Bifrost ODBC permission sets wired into the Foundation Full and Read roles, AL-Go CI/CD and source guards (epic businesscentralal/bifrost-support#36).
