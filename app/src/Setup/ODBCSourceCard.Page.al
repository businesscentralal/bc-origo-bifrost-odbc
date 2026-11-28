namespace Origo.Bifrost.ODBC;

/// <summary>
/// Card for one ODBC source. The connection string or DSN and the AES key are entered through a dialog and are never shown again.
/// </summary>
page 10035498 "ODBC Source Card ori"
{
    Caption = 'ODBC Source', Comment = 'is-IS=ODBC-uppspretta';
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "ODBC Source ori";
    Extensible = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General', Comment = 'is-IS=Almennt';
                field(Code; Rec.Code)
                {
                    ToolTip = 'Specifies the code of the ODBC source.', Comment = 'is-IS=Tilgreinir kóða ODBC-uppsprettunnar.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies a description of the ODBC source.', Comment = 'is-IS=Tilgreinir lýsingu ODBC-uppsprettunnar.';
                }
                field(Transport; Rec.Transport)
                {
                    ToolTip = 'Specifies the transport implementation used to reach the ODBC source.', Comment = 'is-IS=Tilgreinir flutningsleiðina sem notuð er til að ná í ODBC-uppsprettuna.';
                }
                field("Relay Connection Code"; Rec."Relay Connection Code")
                {
                    ToolTip = 'Specifies the relay connection used to reach the source.', Comment = 'is-IS=Tilgreinir relay-tenginguna sem notuð er til að ná í uppsprettuna.';
                }
                field("Blob Container Code"; Rec."Blob Container Code")
                {
                    ToolTip = 'Specifies the optional blob container used for large results.', Comment = 'is-IS=Tilgreinir valkvæma blob-gáminn sem notaður er fyrir stórar niðurstöður.';
                }
                field("Driver Name"; Rec."Driver Name")
                {
                    ToolTip = 'Specifies the driver or database system name reported by the last connection test.', Comment = 'is-IS=Tilgreinir heiti rekils eða gagnagrunnskerfis úr síðustu tengiprófun.';
                }
            }
            group(Limits)
            {
                Caption = 'Access and limits', Comment = 'is-IS=Aðgangur og takmarkanir';
                field("Read Only"; Rec."Read Only")
                {
                    ToolTip = 'Specifies that the source can only be read. Statements that change data are refused.', Comment = 'is-IS=Tilgreinir að aðeins sé hægt að lesa uppsprettuna. Skipunum sem breyta gögnum er hafnað.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ToolTip = 'Specifies that the source is blocked and cannot be used.', Comment = 'is-IS=Tilgreinir að uppsprettan sé læst og ekki hægt að nota hana.';
                }
                field("Row Cap"; Rec."Row Cap")
                {
                    ToolTip = 'Specifies the maximum number of rows a query returns.', Comment = 'is-IS=Tilgreinir hámarksfjölda lína sem fyrirspurn skilar.';
                }
                field("Inline Result Limit (KB)"; Rec."Inline Result Limit (KB)")
                {
                    ToolTip = 'Specifies the largest query result, in KB of JSON, that ODBC.Query.Run returns inline. Larger results are stored in Blob Staging and the response returns a stagingId. The default is 1024 KB and the maximum is 15360 KB.', Comment = 'is-IS=Tilgreinir stærstu niðurstöðu fyrirspurnar, í KB af JSON, sem ODBC.Query.Run skilar beint. Stærri niðurstöður eru vistaðar í Blob Staging og svarið skilar stagingId. Sjálfgefið er 1024 KB og hámarkið er 15360 KB.';
                }
                field("Timeout (s)"; Rec."Timeout (s)")
                {
                    ToolTip = 'Specifies the number of seconds before a query times out.', Comment = 'is-IS=Tilgreinir fjölda sekúndna áður en fyrirspurn rennur út á tíma.';
                }
            }
            group(Secrets)
            {
                Caption = 'Secrets', Comment = 'is-IS=Leyndarmál';
                field(HasConnectionString; HasConnectionString)
                {
                    Caption = 'Has connection string', Comment = 'is-IS=Tengistrengur til';
                    ToolTip = 'Specifies whether a connection string or DSN is stored. It is never shown.', Comment = 'is-IS=Tilgreinir hvort tengistrengur eða DSN er geymt. Það er aldrei sýnt.';
                    Editable = false;
                }
                field(HasAesKey; HasAesKey)
                {
                    Caption = 'Has AES key', Comment = 'is-IS=AES-lykill til';
                    ToolTip = 'Specifies whether an AES key is stored. It is never shown.', Comment = 'is-IS=Tilgreinir hvort AES-lykill er geymdur. Hann er aldrei sýndur.';
                    Editable = false;
                }
                field("AES Vector"; Rec."AES Vector")
                {
                    ToolTip = 'Specifies the AES initialization vector. It is not secret.', Comment = 'is-IS=Tilgreinir AES-upphafsvigurinn. Hann er ekki leynilegur.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SetConnectionString)
            {
                Caption = 'Set connection string', Comment = 'is-IS=Setja tengistreng';
                ToolTip = 'Enters the connection string or DSN. It is kept in isolated storage and is never shown again.', Comment = 'is-IS=Setur inn tengistreng eða DSN. Það er geymt í einangraðri geymslu og er aldrei sýnt aftur.';
                Image = EncryptionKeys;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                begin
                    EnterSecret(Enum::"ODBC Secret Kind ori"::ConnectionString);
                end;
            }
            action(SetAesKey)
            {
                Caption = 'Set AES key', Comment = 'is-IS=Setja AES-lykil';
                ToolTip = 'Enters the AES key. It is kept in isolated storage and is never shown again.', Comment = 'is-IS=Setur inn AES-lykilinn. Hann er geymdur í einangraðri geymslu og er aldrei sýndur aftur.';
                Image = EncryptionKeys;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                begin
                    EnterSecret(Enum::"ODBC Secret Kind ori"::AesKey);
                end;
            }
            action(ValidateSetup)
            {
                Caption = 'Validate setup', Comment = 'is-IS=Sannreyna uppsetningu';
                ToolTip = 'Checks that the source is not blocked and that the relay connection and all secrets are set.', Comment = 'is-IS=Athugar að uppsprettan sé ekki læst og að relay-tenging og öll leyndarmál séu til staðar.';
                Image = CheckList;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                var
                    SetupValidation: Codeunit "ODBC Setup Validation ori";
                begin
                    CurrPage.SaveRecord();
                    SetupValidation.ValidateSetup(Rec.Code);
                    Message(SetupOkMsg);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateIndicators();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        HasConnectionString := false;
        HasAesKey := false;
    end;

    local procedure UpdateIndicators()
    var
        SecretMgt: Codeunit "ODBC Secret Mgt ori";
    begin
        HasConnectionString := SecretMgt.HasSecret(Rec.SystemId, Enum::"ODBC Secret Kind ori"::ConnectionString);
        HasAesKey := SecretMgt.HasSecret(Rec.SystemId, Enum::"ODBC Secret Kind ori"::AesKey);
    end;

    local procedure EnterSecret(SecretKind: Enum "ODBC Secret Kind ori")
    var
        SecretMgt: Codeunit "ODBC Secret Mgt ori";
        SecretEntry: Page "ODBC Secret Entry ori";
    begin
        CurrPage.SaveRecord();
        if Rec.Code = '' then
            Error(SaveFirstErr);
        if SecretEntry.RunModal() = Action::OK then
            SecretMgt.SetSecret(Rec.SystemId, SecretKind, SecretEntry.GetSecret());
        UpdateIndicators();
    end;

    var
        HasConnectionString: Boolean;
        HasAesKey: Boolean;
        SaveFirstErr: Label 'Enter a code before you set a secret.', Comment = 'is-IS=Sláðu inn kóða áður en þú setur leyndarmál.';
        SetupOkMsg: Label 'The ODBC source is set up completely.', Comment = 'is-IS=ODBC-uppsprettan er fullkomlega uppsett.';
}
