namespace Origo.Bifrost.ODBC.Test;

using Origo.Bifrost.ODBC;

/// <summary>Adds the mock transport only while the test app is installed.</summary>
enumextension 98121 "ODBC Mock Transport ori" extends "ODBC Transport ori"
{
    /// <summary>In-memory transport that cannot make network calls.</summary>
    value(98121; Mock)
    {
        Caption = 'Mock', Locked = true;
        Implementation = "ODBC Transport ori" = "ODBC Mock Transport ori";
    }
}
