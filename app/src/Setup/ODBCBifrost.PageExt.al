namespace Origo.Bifrost.ODBC;

using Origo.Bifrost;

/// <summary>
/// Adds the ODBC setup to the Related menu of the Bifröst page, right after Bifrost Setup.
/// </summary>
pageextension 10035524 "ODBC Bifrost ori" extends "Bifrost ori"
{
    actions
    {
        addafter(BifrostSetup)
        {
            action(ODBCSetup)
            {
                ApplicationArea = All;
                Caption = 'Bifrost ODBC Setup', Comment = 'is-IS=Uppsetning Bifröst ODBC';
                ToolTip = 'Open the ODBC sources, where Bifrost ODBC is set up.', Comment = 'is-IS=Opna ODBC-uppsprettur þar sem Bifröst ODBC er sett upp.';
                Image = Setup;
                RunObject = page "ODBC Sources ori";
            }
        }
    }
}
