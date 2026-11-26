namespace Origo.Bifrost.ODBC;

/// <summary>
/// Full Bifrost ODBC role. Edits the ODBC setup. Secrets are entered through a dialog and are never shown.
/// </summary>
permissionset 10035487 "BIFROST ODBCFull ori"
{
    Assignable = true;
    Access = Public;
    Caption = 'Bifrost ODBC Full', MaxLength = 30, Comment = 'is-IS=Bifröst - ODBC (fullt)';
    IncludedPermissionSets = "BIFROST ODBCRead ori";
    Permissions =
        tabledata "ODBC Relay Connection ori" = RIMD,
        tabledata "ODBC Blob Container ori" = RIMD,
        tabledata "ODBC Source ori" = RIMD;
}
