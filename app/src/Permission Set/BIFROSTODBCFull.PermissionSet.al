namespace Origo.Bifrost.ODBC;

/// <summary>
/// Full Bifrost ODBC role. In the scaffold it grants registration only; write message types add their grants here.
/// </summary>
permissionset 10035487 "BIFROST ODBCFull ori"
{
    Assignable = true;
    Access = Public;
    Caption = 'Bifrost ODBC Full', MaxLength = 30, Comment = 'is-IS=Bifröst - ODBC (fullt)';
    IncludedPermissionSets = "BIFROST ODBC ori";
}
