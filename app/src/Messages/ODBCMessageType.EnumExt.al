namespace Origo.Bifrost.ODBC;

using Origo.Bifrost;

/// <summary>Registers the four read-only ODBC message contracts.</summary>
enumextension 10035516 "ODBC Message Type ori" extends "Message Type ori"
{
    /// <summary>Lists configured ODBC sources without connection details.</summary>
    value(10035517; "ODBC.Source.List")
    {
        Caption = 'ODBC.Source.List', Locked = true;
        Implementation = "Msg Interface ori" = "ODBC Src List Impl ori", "Msg Discovery ori" = "ODBC Src List Impl ori", "Msg Contract ori" = "ODBC Src List Impl ori";
    }
    /// <summary>Tests an ODBC source and returns its driver and database identity.</summary>
    value(10035518; "ODBC.Source.Test")
    {
        Caption = 'ODBC.Source.Test', Locked = true;
        Implementation = "Msg Interface ori" = "ODBC Src Test Impl ori", "Msg Discovery ori" = "ODBC Src Test Impl ori", "Msg Contract ori" = "ODBC Src Test Impl ori";
    }
    /// <summary>Reads tables, views and columns from an ODBC source.</summary>
    value(10035519; "ODBC.Schema.Get")
    {
        Caption = 'ODBC.Schema.Get', Locked = true;
        Implementation = "Msg Interface ori" = "ODBC Schema Get Impl ori", "Msg Discovery ori" = "ODBC Schema Get Impl ori", "Msg Contract ori" = "ODBC Schema Get Impl ori";
    }
    /// <summary>Runs one read-only SELECT with positional parameters and a row limit.</summary>
    value(10035520; "ODBC.Query.Run")
    {
        Caption = 'ODBC.Query.Run', Locked = true;
        Implementation = "Msg Interface ori" = "ODBC Query Run Impl ori", "Msg Discovery ori" = "ODBC Query Run Impl ori", "Msg Contract ori" = "ODBC Query Run Impl ori";
    }
}
