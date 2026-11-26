namespace Origo.Bifrost.ODBC;

/// <summary>
/// An Azure Relay hybrid connection through which Business Central reaches the Bifrost local agent.
/// The SAS key is kept in IsolatedStorage only.
/// </summary>
table 10035491 "ODBC Relay Connection ori"
{
    Caption = 'ODBC Relay Connection', Comment = 'is-IS=ODBC relay-tenging';
    DataClassification = CustomerContent;
    LookupPageId = "ODBC Relay Connections ori";
    DrillDownPageId = "ODBC Relay Connections ori";

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
        field(3; "Relay Namespace"; Text[100])
        {
            Caption = 'Azure Relay namespace', Comment = 'is-IS=Azure Relay nafnrými';
        }
        field(4; "Hybrid Connection Name"; Text[100])
        {
            Caption = 'Hybrid connection name', Comment = 'is-IS=Heiti hybrid-tengingar';
        }
        field(5; "SAS Key Name"; Text[100])
        {
            Caption = 'SAS key name', Comment = 'is-IS=Heiti SAS-lykils';
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
        ODBCSource.SetRange("Relay Connection Code", Code);
        if not ODBCSource.IsEmpty() then
            Error(InUseErr, Code);
        SecretMgt.DeleteAllSecrets(SystemId);
    end;

    var
        InUseErr: Label 'The relay connection %1 is used by an ODBC source and cannot be deleted.', Comment = '%1 = relay connection code; is-IS=Relay-tengingin %1 er notuð af ODBC-uppsprettu og er ekki hægt að eyða henni.';
}
