namespace Origo.Bifrost.ODBC.Test;

using Origo.Bifrost;
using Origo.Bifrost.ODBC;
using System.Environment.Configuration;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

/// <summary>
/// Supplies platform reads and execute on the test codeunits and libraries for the restricted tests.
/// Product execute and administrator permissions must come from the real product roles.
/// </summary>
permissionset 98101 "ODBC Setup Test ori"
{
    Assignable = true;
    Caption = 'Setup test platform', Locked = true;
    IncludedPermissionSets = "Guided Experience - View";
    Permissions =
        tabledata "NAV App Setting" = r,
        tabledata "Setup ori" = R,
        tabledata "ODBC Relay Connection ori" = RIMD,
        tabledata "ODBC Blob Container ori" = RIMD,
        tabledata "ODBC Source ori" = RIMD,
        table "ODBC Relay Connection ori" = X,
        table "ODBC Blob Container ori" = X,
        table "ODBC Source ori" = X,
        codeunit "ODBC Secret Mgt ori" = X,
        codeunit "ODBC Setup Validation ori" = X,
        codeunit "ODBC Setup Tst ori" = X,
        codeunit "ODBC Scaffold Tst ori" = X,
        codeunit "Library Assert" = X,
        codeunit "Library - Lower Permissions" = X,
        codeunit "Permissions Mock" = X,
        codeunit "ODBC Client ori" = X,
        codeunit "ODBC Reader ori" = X,
        codeunit "ODBC Mock Transport ori" = X,
        codeunit "ODBC Client Tst ori" = X;
}
