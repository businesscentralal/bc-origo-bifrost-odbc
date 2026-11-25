namespace Origo.Bifrost.ODBC;

/// <summary>
/// Card for one ODBC Blob Container record. The secret is entered through a dialog and is never shown again.
/// </summary>
page 10035496 "ODBC Blob Container Card ori"
{
    Caption = 'ODBC Blob Container', Comment = 'is-IS=ODBC blob-gámur';
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "ODBC Blob Container ori";
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
                    ToolTip = 'Specifies the code of the blob container.', Comment = 'is-IS=Tilgreinir kóða blob-gámsins.';
                }
                field("Description"; Rec."Description")
                {
                    ToolTip = 'Specifies a description of the blob container.', Comment = 'is-IS=Tilgreinir lýsingu blob-gámsins.';
                }
                field("Storage Account"; Rec."Storage Account")
                {
                    ToolTip = 'Specifies the storage account.', Comment = 'is-IS=Tilgreinir geymslureikninginn.';
                }
                field("Container Name"; Rec."Container Name")
                {
                    ToolTip = 'Specifies the name of the container.', Comment = 'is-IS=Tilgreinir heiti gámsins.';
                }
                field("Auth Type"; Rec."Auth Type")
                {
                    ToolTip = 'Specifies how Business Central authenticates against the container.', Comment = 'is-IS=Tilgreinir hvernig Business Central auðkennir sig gagnvart gámnum.';
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
                Caption = 'Set secret', Comment = 'is-IS=Setja leyndarmál';
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
        HasSecret := SecretMgt.HasSecret(Rec.SystemId, Enum::"ODBC Secret Kind ori"::BlobSecret);
    end;

    local procedure EnterSecret()
    var
        SecretEntry: Page "ODBC Secret Entry ori";
        SecretMgt: Codeunit "ODBC Secret Mgt ori";
    begin
        CurrPage.SaveRecord();
        if Rec.Code = '' then
            Error(SaveFirstErr);
        if SecretEntry.RunModal() = Action::OK then
            SecretMgt.SetSecret(Rec.SystemId, Enum::"ODBC Secret Kind ori"::BlobSecret, SecretEntry.GetSecret());
        UpdateIndicator();
    end;

    var
        HasSecret: Boolean;
        SaveFirstErr: Label 'Enter a code before you set a secret.', Comment = 'is-IS=Sláðu inn kóða áður en þú setur leyndarmál.';
}
