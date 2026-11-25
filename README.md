# Bifröst ODBC

**App name:** Bifrost ODBC
**Publisher:** Origo — **Version:** 28.0.0.0 — **Target:** Cloud (BC 28.0, runtime 17.0)
**App ID:** `a83ef9e7-287e-4a1d-922c-c30686c4fd5d` — **Test app ID:** `9ba2022b-f908-46b7-a42d-312f204d0e15`
**Object ID range:** 10035485–10035534 (tests 98100–98199) — **Namespace:** `Origo.Bifrost.ODBC`

Bifrost ODBC lets an agent read data from any ODBC data source next to the customer's Business Central — SQL Server,
Oracle, MySQL, PostgreSQL, DB2, Access, Excel and others — through the Bifröst local agent and Azure Relay. Business
Central never opens a database connection itself, and agents get read-only access.

**Status:** scaffold. The setup, AL API, message types and the on-premises agent are built under epic
businesscentralal/bifrost-support#36.

Foundation discovers this app on **Bifrost Setup** through its application registry. Assign `BIFROST ODBC ori`,
`BIFROST ODBCFull ori` or `BIFROST ODBCRead ori` alongside the appropriate Foundation role. The object allocation is
recorded in [.claude/CLAUDE.md](.claude/CLAUDE.md).
