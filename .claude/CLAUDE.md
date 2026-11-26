# Extension: Bifrost ODBC

## Customer
Origo / AppSource

## Prefix
(none - objects use raw names with the mandatory `ori` suffix inside the `Origo.Bifrost.ODBC` namespace; same as Bifrost Subscription Billing)

## Namespace
Origo.Bifrost.ODBC (tests: Origo.Bifrost.ODBC.Test)

## Object ID Range
App:   10035485-10035534 (Public 1; registered in the OneDrive object-range workbook 25.11.2026, Gunnar's decision card d-20261125-sql-object-range)
Tests: 98100-98199 (workbook sheet Test App Ranges, row 99014)

| Type | ID | Name |
| --- | --- | --- |
| Codeunit | 10035485 | ODBC Registration ori |
| Permission set | 10035486 | BIFROST ODBC ori |
| Permission set | 10035487 | BIFROST ODBCFull ori |
| Permission set | 10035488 | BIFROST ODBCRead ori |
| Permission set extension | 10035489 | ODBC Full Role ori |
| Permission set extension | 10035490 | ODBC Read Role ori |
| Enum | 10035500 | ODBC Blob Auth Type ori |
| Table | 10035491 | ODBC Relay Connection ori |
| Table | 10035492 | ODBC Blob Container ori |
| Table | 10035493 | ODBC Source ori |
| Page | 10035494 | ODBC Relay Connection Card ori |
| Page | 10035495 | ODBC Relay Connections ori |
| Page | 10035496 | ODBC Blob Container Card ori |
| Page | 10035497 | ODBC Blob Containers ori |
| Page | 10035498 | ODBC Source Card ori |
| Page | 10035499 | ODBC Sources ori |
| Codeunit | 10035501 | ODBC Secret Mgt ori |
| Codeunit | 10035502 | ODBC Setup Validation ori |
| Page | 10035503 | ODBC Secret Entry ori |
| Enum | 10035504 | ODBC Secret Kind ori |
| Codeunit | 10035506 | ODBC Client ori |
| Codeunit | 10035507 | ODBC Reader ori |
| Interface | (no ID) | ODBC Transport ori |
| Enum | 10035508 | ODBC Transport ori |
| Codeunit | 10035509 | ODBC Relay Transport ori |
| Codeunit | 10035510 | ODBC Blob Transport ori |
| Test codeunit | 98120 | ODBC Client Tst ori |
| Test enum extension | 98121 | ODBC Mock Transport ori |
| Test codeunit | 98122 | ODBC Mock Transport ori |
| Test codeunit | 98130 | ODBC Agent Crypto Tst ori |
| Test codeunit | 98102 | ODBC Setup Tst ori |
| Test codeunit | 98100 | ODBC Scaffold Tst ori |
| Test permission set | 98101 | ODBC Setup Test ori |

Every new object is added to this table in the same PR.

## Product scope (epic businesscentralal/bifrost-support#36, Gunnar's decisions 25.11.2026)
- Read any ODBC data source next to the customer's Business Central through the **Bifröst local agent** (an on-premises
  Windows service using the ODBC driver manager) over **Azure Relay** hybrid connections; large results through Azure Blob.
- BC never opens a database connection itself. Connection strings / DSNs are stored in IsolatedStorage and sent
  AES-encrypted end to end; they never appear in a response, log or help text.
- **Read-only for agents.** Message types: `ODBC.Source.List`, `ODBC.Source.Test`, `ODBC.Schema.Get`, `ODBC.Query.Run`.
  There is **no write message type**. `Execute` exists only as an AL API for PTEs and migration code, refused on sources
  marked Read Only (the default).
- Reference implementation of the relay/AES/blob transport: Origo Data Migration (ADO BC-PTE-DataMigration,
  `app/src/General/SQL Sync`). Rewrite to Bifröst standards; never copy-paste.

## Setup Notifications
Setup notifications live **only** on Bifröst Foundation's `Setup ori` page. This app never raises a `Notification` of its own.
It registers with Foundation through `App Registry ori.OnRegisterApps` (`app/src/Common/ODBCRegistration.Codeunit.al`).

## Target BC Version
28.0 (application 28.0.0.0, platform 28.0.0.0, runtime 17.0)

## Source Control
Platform: GitHub
Organization: businesscentralal
Repository: bc-origo-bifrost-odbc
Default branch: main

## Dependencies
- Bifrost Foundation (`7505e808-6e52-4b96-a328-82573391297a`, 28.0.16.0)

App ID `a83ef9e7-287e-4a1d-922c-c30686c4fd5d`, test app ID `9ba2022b-f908-46b7-a42d-312f204d0e15`.

## Naming Rules
- Every object carries the `ori` suffix (AppSource mandatory affix), max 30 characters; permission set names max 20.
- Message type names have three parts: `Domain.Entity.Action`, domain `ODBC`.
- Icelandic captions use "Bifröst".

## Development Standards
This project follows the **Origo BC Development Standards** (https://github.com/OrigoSoftwareSolutions/bc-dev-standards).
Before writing any AL code, load `origo-bc-al-coding-standards`, `origo-bc-test-writer`, `origo-bc-documentation-writer`.
- Namespace at the top of every file; XML documentation on every object and non-local procedure
- Bilingual captions (en-US + is-IS) via `Comment = 'is-IS=...'`; regenerate `app/Translations/Bifrost ODBC.is-IS.xlf` with `tools/Update-IcelandicXlf.ps1`
- Implementation = code + tests + documentation (contract chapters of `Msg Contract ori`)

## Message Type Conventions
- One enum extension of Foundation's `Message Type ori`; keys are the published API contract and are never renamed.
- Each type has an Impl codeunit implementing `Msg Interface ori`, `Msg Discovery ori` and `Msg Contract ori`.
- Help text is public: no customer names, tenant ids, internal hosts, connection strings or credentials.

## Test App Rules
- Unit tests never need credentials and never call a relay: use the mock relay client (interface + enum in setup).
- Every message type is tested in languages 1033 and 1039.
