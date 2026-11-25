namespace Origo.Bifrost.ODBC;

/// <summary>
/// Read-only Bifrost ODBC role. Reads the ODBC setup (relay connections, blob containers, sources); never edits it and never exposes secrets.
/// </summary>
permissionset 10035488 "BIFROST ODBCRead ori"
{
    Assignable = true;
    Access = Public;
    Caption = 'Bifrost ODBC Read', MaxLength = 30, Comment = 'is-IS=Bifröst - ODBC (lestur)';
    IncludedPermissionSets = "BIFROST ODBC ori";
    Permissions =
        tabledata "ODBC Relay Connection ori" = R,
        tabledata "ODBC Blob Container ori" = R,
        tabledata "ODBC Source ori" = R,
        table "ODBC Relay Connection ori" = X,
        table "ODBC Blob Container ori" = X,
        table "ODBC Source ori" = X,
        page "ODBC Relay Connection Card ori" = X,
        page "ODBC Relay Connections ori" = X,
        page "ODBC Blob Container Card ori" = X,
        page "ODBC Blob Containers ori" = X,
        page "ODBC Source Card ori" = X,
        page "ODBC Sources ori" = X,
        page "ODBC Secret Entry ori" = X,
        codeunit "ODBC Secret Mgt ori" = X,
        codeunit "ODBC Setup Validation ori" = X;
}
