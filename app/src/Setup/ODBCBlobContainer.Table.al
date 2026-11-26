namespace Origo.Bifrost.ODBC;

/// <summary>
/// An Azure Blob container for results too large for the relay. The secret is kept in IsolatedStorage only.
/// </summary>
table 10035492 "ODBC Blob Container ori"
{
    Caption = 'ODBC Blob Container', Comment = 'is-IS=ODBC blob-gámur';
    DataClassification = CustomerContent;
    LookupPageId = "ODBC Blob Containers ori";
    DrillDownPageId = "ODBC Blob Containers ori";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code', Comment = 'is-IS=Kóði';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description', Comment = 'is-IS=Lýsing';
        }
        field(3; "Storage Account"; Text[100])
        {
            Caption = 'Storage account', Comment = 'is-IS=Geymslureikningur';
        }
        field(4; "Container Name"; Text[100])
        {
            Caption = 'Container', Comment = 'is-IS=Gámur';
        }
        field(5; "Auth Type"; Enum "ODBC Blob Auth Type ori")
        {
            Caption = 'Authentication type', Comment = 'is-IS=Auðkenningartegund';
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    var
        ODBCSource: Record "ODBC Source ori";
        SecretMgt: Codeunit "ODBC Secret Mgt ori";
    begin
        ODBCSource.SetRange("Blob Container Code", Code);
        if not ODBCSource.IsEmpty() then
            Error(InUseErr, Code);
        SecretMgt.DeleteAllSecrets(SystemId);
    end;

    var
        InUseErr: Label 'The blob container %1 is used by an ODBC source and cannot be deleted.', Comment = '%1 = blob container code; is-IS=Blob-gámurinn %1 er notaður af ODBC-uppsprettu og er ekki hægt að eyða honum.';
}
