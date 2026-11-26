namespace Origo.Bifrost.ODBC.Test;

using Origo.Bifrost.ODBC;

/// <summary>In-memory agent and telemetry observer. It has no HTTP client and uses only fake fixtures.</summary>
codeunit 98122 "ODBC Mock Transport ori" implements "ODBC Transport ori"
{
    SingleInstance = true;

    /// <summary>Resets all state between tests.</summary>
    procedure Reset()
    begin
        Clear(LastRequest);
        Clear(Reply);
        Clear(LastOperation);
        Clear(LastDimensions);
        Calls := 0;
        Events := 0;
        RaiseFailure := false;
    end;

    /// <summary>Sets the agent JSON response.</summary>
    /// <param name="Body">Response JSON.</param>
    procedure SetResponse(Body: Text)
    begin
        Reply.ReadFrom(Body);
    end;

    /// <summary>Enables a transport failure that deliberately includes fake credentials.</summary>
    procedure Fail()
    begin
        RaiseFailure := true;
    end;

    /// <summary>Captures a request and returns the configured response without any external calls.</summary>
    /// <param name="Source">Validated source.</param>
    /// <param name="Operation">Requested operation.</param>
    /// <param name="Request">Captured request.</param>
    /// <param name="Response">Configured response.</param>
    procedure Send(Source: Record "ODBC Source ori"; Operation: Text; Request: JsonObject; var Response: JsonObject)
    begin
        Calls += 1;
        LastRequest := Request.Clone().AsObject();
        LastOperation := Operation;
        if RaiseFailure then
            Error('Mock failure: Driver={Mock};Server=example.invalid;Password=x-unit-only; MDEyMzQ1Njc4OWFiY2RlZg== fake-relay-key');
        Response := Reply.Clone().AsObject();
    end;

    /// <summary>Returns captured request and invocation count.</summary>
    /// <param name="Request">Last request.</param>
    /// <returns>Transport calls since Reset.</returns>
    procedure GetRequest(var Request: JsonObject): Integer
    begin
        Request := LastRequest;
        exit(Calls);
    end;

    /// <summary>Returns telemetry dimensions and invocation count.</summary>
    /// <param name="Result">Metadata-only dimensions.</param>
    /// <returns>Events since Reset.</returns>
    procedure GetTelemetry(var Result: Dictionary of [Text, Text]): Integer
    begin
        Result := LastDimensions;
        exit(Events);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ODBC Client ori", 'OnCallCompleted', '', false, false)]
    local procedure ObserveCall(Dimensions: Dictionary of [Text, Text])
    begin
        LastDimensions := Dimensions;
        Events += 1;
    end;

    var
        LastRequest: JsonObject;
        Reply: JsonObject;
        LastOperation: Text;
        LastDimensions: Dictionary of [Text, Text];
        Calls: Integer;
        Events: Integer;
        RaiseFailure: Boolean;
}
