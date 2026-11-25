namespace Origo.Bifrost.ODBC;

/// <summary>
/// Grants Bifrost ODBC scaffold execution without access to external data sources.
/// Message types add their own permissions here as they are built.
/// </summary>
permissionset 10035486 "BIFROST ODBC ori"
{
    Assignable = true;
    Access = Public;
    Caption = 'Bifrost ODBC', MaxLength = 30, Comment = 'is-IS=Bifröst - ODBC';
    Permissions = codeunit "ODBC Registration ori" = X;
}
