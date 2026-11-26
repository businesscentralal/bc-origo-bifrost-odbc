namespace Origo.Bifrost.ODBC;

/// <summary>
/// Lists the ODBC Relay Connections records.
/// </summary>
page 10035495 "ODBC Relay Connections ori"
{
    Caption = 'ODBC Relay Connections', Comment = 'is-IS=ODBC relay-tengingar';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "ODBC Relay Connection ori";
    CardPageId = "ODBC Relay Connection Card ori";
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
            }
        }
    }
}
