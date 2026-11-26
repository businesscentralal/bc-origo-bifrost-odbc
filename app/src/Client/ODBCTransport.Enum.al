namespace Origo.Bifrost.ODBC;

/// <summary>Extensible transport selection; tests add their mock implementation in the test app.</summary>
enum 10035508 "ODBC Transport ori" implements "ODBC Transport ori"
{
    Extensible = true;
    DefaultImplementation = "ODBC Transport ori" = "ODBC Relay Transport ori";

    /// <summary>Azure Relay transport to the local agent.</summary>
    value(0; Relay)
    {
        Caption = 'Relay', Comment = 'is-IS=Relay';
        Implementation = "ODBC Transport ori" = "ODBC Relay Transport ori";
    }
}
