namespace Origo.Bifrost.ODBC;

/// <summary>
/// Dialog for entering one secret. The value is masked, handed to the caller as SecretText and never shown again.
/// </summary>
page 10035503 "ODBC Secret Entry ori"
{
    Caption = 'Enter Secret', Comment = 'is-IS=Setja inn leyndarmál';
    PageType = StandardDialog;
    ApplicationArea = All;
    Extensible = false;

    layout
    {
        area(Content)
        {
            field(SecretValue; SecretInput)
            {
                Caption = 'Secret', Comment = 'is-IS=Leyndarmál';
                ToolTip = 'Specifies the secret to store. It is kept in isolated storage and is never shown again. Leave it empty to remove the stored secret.', Comment = 'is-IS=Tilgreinir leyndarmálið sem á að geyma. Það er geymt í einangraðri geymslu og er aldrei sýnt aftur. Hafðu reitinn auðan til að fjarlægja geymda leyndarmálið.';
                ExtendedDatatype = Masked;
                NotBlank = false;
            }
        }
    }

    /// <summary>Returns the entered secret.</summary>
    /// <returns>The secret as SecretText.</returns>
    procedure GetSecret(): SecretText
    begin
        exit(SecretInput);
    end;

    var
        SecretInput: Text[1000];
}
