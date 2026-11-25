namespace Origo.Bifrost.ODBC;

/// <summary>
/// The kinds of secret the ODBC setup keeps in IsolatedStorage. Secrets are never stored in tables.
/// </summary>
enum 10035504 "ODBC Secret Kind ori"
{
    Extensible = false;
    Access = Public;

    value(0; RelaySasKey)
    {
        Caption = 'Relay SAS key', Comment = 'is-IS=SAS-lykill relay';
    }
    value(1; BlobSecret)
    {
        Caption = 'Blob container secret', Comment = 'is-IS=Leyndarmál blob-gáms';
    }
    value(2; ConnectionString)
    {
        Caption = 'Connection string or DSN', Comment = 'is-IS=Tengistrengur eða DSN';
    }
    value(3; AesKey)
    {
        Caption = 'AES key', Comment = 'is-IS=AES-lykill';
    }
}
