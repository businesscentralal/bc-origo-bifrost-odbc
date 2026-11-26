namespace Origo.Bifrost.ODBC;

/// <summary>
/// Lists the ODBC Sources records.
/// </summary>
page 10035499 "ODBC Sources ori"
{
    Caption = 'ODBC Sources', Comment = 'is-IS=ODBC-uppsprettur';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "ODBC Source ori";
    CardPageId = "ODBC Source Card ori";
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
                    ToolTip = 'Specifies the code of the ODBC source.', Comment = 'is-IS=Tilgreinir kóða ODBC-uppsprettunnar.';
                }
                field("Description"; Rec."Description")
                {
                    ToolTip = 'Specifies a description of the ODBC source.', Comment = 'is-IS=Tilgreinir lýsingu ODBC-uppsprettunnar.';
                }
                field("Relay Connection Code"; Rec."Relay Connection Code")
                {
                    ToolTip = 'Specifies the relay connection used to reach the source.', Comment = 'is-IS=Tilgreinir relay-tenginguna sem notuð er til að ná í uppsprettuna.';
                }
                field("Read Only"; Rec."Read Only")
                {
                    ToolTip = 'Specifies that the source can only be read.', Comment = 'is-IS=Tilgreinir að aðeins sé hægt að lesa uppsprettuna.';
                }
                field("Blocked"; Rec."Blocked")
                {
                    ToolTip = 'Specifies that the source is blocked.', Comment = 'is-IS=Tilgreinir að uppsprettan sé læst.';
                }
            }
        }
    }
}
