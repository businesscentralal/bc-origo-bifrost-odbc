namespace Origo.Bifrost.ODBC;

/// <summary>
/// Read-only Bifrost ODBC role. In the scaffold it grants registration only; read message types add their grants here.
/// </summary>
permissionset 10035488 "BIFROST ODBCRead ori"
{
    Assignable = true;
    Access = Public;
    Caption = 'Bifrost ODBC Read', MaxLength = 30, Comment = 'is-IS=Bifröst - ODBC (lestur)';
    IncludedPermissionSets = "BIFROST ODBC ori";
}
