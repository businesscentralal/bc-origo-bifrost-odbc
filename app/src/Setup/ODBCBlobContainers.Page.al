namespace Origo.Bifrost.ODBC;

/// <summary>
/// Lists the ODBC Blob Containers records.
/// </summary>
page 10035497 "ODBC Blob Containers ori"
{
    Caption = 'ODBC Blob Containers', Comment = 'is-IS=ODBC blob-gámar';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "ODBC Blob Container ori";
    CardPageId = "ODBC Blob Container Card ori";
    Editable = false;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(Records)
            {
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
            }
        }
    }
}
