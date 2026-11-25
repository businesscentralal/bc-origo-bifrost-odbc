namespace Origo.Bifrost.ODBC;

/// <summary>
/// A named ODBC data source next to the customer's Business Central, reached through a relay connection.
/// The connection string or DSN and the AES key are kept in IsolatedStorage only.
/// </summary>
table 10035493 "ODBC Source ori"
{
    Caption = 'ODBC Source', Comment = 'is-IS=ODBC-uppspretta';
    DataClassification = CustomerContent;
    LookupPageId = "ODBC Sources ori";
    DrillDownPageId = "ODBC Sources ori";

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
        field(3; "Relay Connection Code"; Code[20])
        {
            Caption = 'Relay connection', Comment = 'is-IS=Relay-tenging';
            TableRelation = "ODBC Relay Connection ori";
        }
        field(4; "Blob Container Code"; Code[20])
        {
            Caption = 'Blob container', Comment = 'is-IS=Blob-gámur';
            TableRelation = "ODBC Blob Container ori";
        }
        field(5; "AES Vector"; Text[32])
        {
            Caption = 'AES vector', Comment = 'is-IS=AES-upphafsvigur';
        }
        field(6; "Read Only"; Boolean)
        {
            Caption = 'Read only', Comment = 'is-IS=Eingöngu lestur';
            InitValue = true;
        }
        field(7; Blocked; Boolean)
        {
            Caption = 'Blocked', Comment = 'is-IS=Læst';
        }
        field(8; "Row Cap"; Integer)
        {
            Caption = 'Row cap', Comment = 'is-IS=Hámark lína';
            InitValue = 10000;
            MinValue = 1;
        }
        field(9; "Timeout (s)"; Integer)
        {
            Caption = 'Timeout (s)', Comment = 'is-IS=Tímamörk (sek.)';
            InitValue = 60;
            MinValue = 1;
        }
        field(10; "Driver Name"; Text[100])
        {
            Caption = 'Driver / DBMS name', Comment = 'is-IS=Heiti rekils / gagnagrunnskerfis';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        if "Row Cap" = 0 then
            "Row Cap" := 10000;
        if "Timeout (s)" = 0 then
            "Timeout (s)" := 60;
    end;

    trigger OnDelete()
    var
        SecretMgt: Codeunit "ODBC Secret Mgt ori";
    begin
        SecretMgt.DeleteAllSecrets(SystemId);
    end;
}
