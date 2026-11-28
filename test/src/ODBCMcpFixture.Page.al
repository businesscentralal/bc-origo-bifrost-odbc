namespace Origo.Bifrost.ODBC.Test;

using Origo.Bifrost.ODBC;

/// <summary>Test-app-only API fixture. Fixed XODBCMCP data and fake keys permit MCP checks without a live agent.</summary>
page 98141 "ODBC MCP Fixture ori"
{
    PageType = API;
    APIPublisher = 'origo';
    APIGroup = 'odbcTests';
    APIVersion = 'v1.0';
    EntityName = 'fixture';
    EntitySetName = 'fixtures';
    SourceTable = "ODBC Source ori";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Caption = 'ODBC mock fixture', Locked = true;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id', Locked = true;
                    Editable = false;
                }
                field(code; Rec.Code)
                {
                    Caption = 'Code', Locked = true;
                }
                field(blocked; Rec.Blocked)
                {
                    Caption = 'Blocked', Locked = true;
                }
                field(rowCap; Rec."Row Cap")
                {
                    Caption = 'Row cap', Locked = true;
                }
                field(inlineResultLimitKB; Rec."Inline Result Limit (KB)")
                {
                    Caption = 'Inline result limit (KB)', Locked = true;
                }
                field(readOnly; Rec."Read Only")
                {
                    Caption = 'Read only', Locked = true;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetRange(Code, 'XODBCMCP');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Relay: Record "ODBC Relay Connection ori";
        SecretMgt: Codeunit "ODBC Secret Mgt ori";
        Fixture: SecretText;
        FakeText: Text;
    begin
        Rec.TestField(Code, 'XODBCMCP');
        if not Relay.Get('XODBCMCP') then begin
            Relay.Code := 'XODBCMCP';
            Relay."Relay Namespace" := 'unit.invalid';
            Relay."Hybrid Connection Name" := 'mock';
            Relay."SAS Key Name" := 'mock';
            Relay.Insert(true);
        end;
        FakeText := 'fake-relay-key';
        Fixture := FakeText;
        SecretMgt.SetSecret(Relay.SystemId, Enum::"ODBC Secret Kind ori"::RelaySasKey, Fixture);
        Rec."Relay Connection Code" := Relay.Code;
        Rec.Transport := Rec.Transport::Mock;
        Rec."AES Vector" := 'MDEyMzQ1Njc4OWFiY2RlZg==';
        Rec."Row Cap" := 2;
        Rec."Timeout (s)" := 17;
        Rec.Insert(true);
        FakeText := 'MDEyMzQ1Njc4OWFiY2RlZg==';
        Fixture := FakeText;
        SecretMgt.SetSecret(Rec.SystemId, Enum::"ODBC Secret Kind ori"::AesKey, Fixture);
        FakeText := 'Driver={Mock};Server=example.invalid;Password=x-unit-only;';
        Fixture := FakeText;
        SecretMgt.SetSecret(Rec.SystemId, Enum::"ODBC Secret Kind ori"::ConnectionString, Fixture);
        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Rec.TestField(Code, 'XODBCMCP');
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    var
        Relay: Record "ODBC Relay Connection ori";
    begin
        Rec.TestField(Code, 'XODBCMCP');
        Rec.Delete(true);
        if Relay.Get('XODBCMCP') then
            Relay.Delete(true);
        exit(false);
    end;
}
