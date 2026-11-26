namespace Origo.Bifrost.ODBC;

/// <summary>
/// Card for one ODBC Relay Connection record. The secret is entered through a dialog and is never shown again.
/// </summary>
page 10035494 "ODBC Relay Connection Card ori"
{
    Caption = 'ODBC Relay Connection', Comment = 'is-IS=ODBC relay-tenging';
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "ODBC Relay Connection ori";
    Extensible = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General', Comment = 'is-IS=Almennt';
                field("Code"; Rec."Code")
                {
                    ToolTip = 'Specifies the code of the relay connection.', Comment = 'is-IS=Tilgreinir kóða relay-tengingarinnar.';
                }
                field("Description"; Rec."Description")
                {
                    ToolTip = 'Specifies a description of the relay connection.', Comment = 'is-IS=Tilgreinir lýsingu relay-tengingarinnar.';
                }
                field("Relay Namespace"; Rec."Relay Namespace")
                {
                    ToolTip = 'Specifies the Azure Relay namespace.', Comment = 'is-IS=Tilgreinir Azure Relay nafnrýmið.';
                }
                field("Hybrid Connection Name"; Rec."Hybrid Connection Name")
                {
                    ToolTip = 'Specifies the name of the hybrid connection.', Comment = 'is-IS=Tilgreinir heiti hybrid-tengingarinnar.';
                }
                field("SAS Key Name"; Rec."SAS Key Name")
                {
                    ToolTip = 'Specifies the name of the shared access policy (SAS key).', Comment = 'is-IS=Tilgreinir heiti sameiginlegrar aðgangsstefnu (SAS-lykils).';
                }
                field(HasSecretField; HasSecret)
                {
                    Caption = 'Has key', Comment = 'is-IS=Lykill til';
                    ToolTip = 'Specifies whether the secret is stored. The secret itself is never shown.', Comment = 'is-IS=Tilgreinir hvort leyndarmálið er geymt. Leyndarmálið sjálft er aldrei sýnt.';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SetSecret)
            {
                Caption = 'Set SAS key', Comment = 'is-IS=Setja SAS-lykil';
                ToolTip = 'Enters the secret. It is kept in isolated storage and is never shown again.', Comment = 'is-IS=Setur inn leyndarmálið. Það er geymt í einangraðri geymslu og er aldrei sýnt aftur.';
                Image = EncryptionKeys;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                begin
                    EnterSecret();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateIndicator();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        HasSecret := false;
    end;

    local procedure UpdateIndicator()
    var
        SecretMgt: Codeunit "ODBC Secret Mgt ori";
    begin
        HasSecret := SecretMgt.HasSecret(Rec.SystemId, Enum::"ODBC Secret Kind ori"::RelaySasKey);
    end;

    local procedure EnterSecret()
    var
        SecretMgt: Codeunit "ODBC Secret Mgt ori";
        SecretEntry: Page "ODBC Secret Entry ori";
    begin
        CurrPage.SaveRecord();
        if Rec.Code = '' then
            Error(SaveFirstErr);
        if SecretEntry.RunModal() = Action::OK then
            SecretMgt.SetSecret(Rec.SystemId, Enum::"ODBC Secret Kind ori"::RelaySasKey, SecretEntry.GetSecret());
        UpdateIndicator();
    end;

    var
        HasSecret: Boolean;
        SaveFirstErr: Label 'Enter a code before you set a secret.', Comment = 'is-IS=Sláðu inn kóða áður en þú setur leyndarmál.';
}
