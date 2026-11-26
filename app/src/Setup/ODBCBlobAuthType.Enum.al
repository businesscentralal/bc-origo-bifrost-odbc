namespace Origo.Bifrost.ODBC;

/// <summary>
/// How Business Central authenticates against the Azure Blob container used for large results.
/// </summary>
enum 10035500 "ODBC Blob Auth Type ori"
{
    Extensible = true;
    Access = Public;

    value(0; SasToken)
    {
        Caption = 'SAS token', Comment = 'is-IS=SAS-tóki';
    }
    value(1; AccountKey)
    {
        Caption = 'Account key', Comment = 'is-IS=Aðgangslykill reiknings';
    }
}
