namespace Origo.Bifrost.ODBC;

/// <summary>Boundary between the public ODBC API and relay implementations.</summary>
interface "ODBC Transport ori"
{
    /// <summary>Sends one request. Return an agent error in the error property; never log request bodies.</summary>
    /// <param name="Source">Validated source configuration.</param>
    /// <param name="Operation">Query, Execute, TestConnection or GetSchema.</param>
    /// <param name="Request">SQL, ordered parameters, limits and encrypted connection string.</param>
    /// <param name="Response">Agent JSON response.</param>
    procedure Send(Source: Record "ODBC Source ori"; Operation: Text; Request: JsonObject; var Response: JsonObject);
}
