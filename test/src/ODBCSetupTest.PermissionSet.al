namespace Origo.Bifrost.ODBC.Test;

using Origo.Bifrost.ODBC;
using System.Environment.Configuration;

/// <summary>
/// Supplies only platform reads for the restricted setup-page regression.
/// Product execute and administrator permissions must come from the real product roles.
/// </summary>
permissionset 98101 "ODBC Setup Test ori"
{
    Assignable = true;
    Caption = 'Setup test platform', Locked = true;
    IncludedPermissionSets = "Guided Experience - View";
    Permissions =
        tabledata "NAV App Setting" = r,
        tabledata "ODBC Relay Connection ori" = RIMD,
        tabledata "ODBC Blob Container ori" = RIMD,
        tabledata "ODBC Source ori" = RIMD,
        table "ODBC Relay Connection ori" = X,
        table "ODBC Blob Container ori" = X,
        table "ODBC Source ori" = X,
        codeunit "ODBC Secret Mgt ori" = X,
        codeunit "ODBC Setup Validation ori" = X;
}
