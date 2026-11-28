namespace Origo.Bifrost.ODBC;

/// <summary>Public, parameterized ODBC API. All operations use the source transport and emit one metadata-only event.</summary>
codeunit 10035506 "ODBC Client ori"
{
    Access = Public;
    InherentPermissions = X;
    InherentEntitlements = X;

    /// <summary>Runs SQL with positional parameters and replaces the reader with the capped result.</summary>
    /// <param name="SourceCode">Configured source.</param>
    /// <param name="SQL">SQL with positional ? placeholders; never concatenated with parameter values.</param>
    /// <param name="Parameters">Parameter values in placeholder order.</param>
    /// <param name="Reader">Forward-only result reader, cleared on failure.</param>
    procedure Query(SourceCode: Code[20]; SQL: Text; Parameters: JsonArray; var Reader: Codeunit "ODBC Reader ori")
    var
        Response: JsonObject;
    begin
        Clear(Reader);
        Call(SourceCode, 'Query', SQL, Parameters, Response, Reader, 0);
    end;

    /// <summary>Runs a read-only query with a per-call cap no greater than the source cap.</summary>
    /// <param name="SourceCode">Configured source.</param>
    /// <param name="SQL">Read statement.</param>
    /// <param name="Parameters">Ordered parameter values.</param>
    /// <param name="MaxRows">Positive cap, no greater than the source row cap.</param>
    /// <param name="Reader">Result cursor.</param>
    procedure Query(SourceCode: Code[20]; SQL: Text; Parameters: JsonArray; MaxRows: Integer; var Reader: Codeunit "ODBC Reader ori")
    var
        Source: Record "ODBC Source ori";
        Response: JsonObject;
    begin
        Clear(Reader);
        Source.Get(SourceCode);
        if (MaxRows < 1) or (MaxRows > Source."Row Cap") then
            Error(InvalidLimitsErr);
        Call(SourceCode, 'Query', SQL, Parameters, Response, Reader, MaxRows);
    end;

    /// <summary>Executes SQL only when Read Only is disabled. This API is for AL callers, never an agent message type.</summary>
    /// <param name="SourceCode">Configured writable source.</param>
    /// <param name="SQL">SQL with positional ? placeholders.</param>
    /// <param name="Parameters">Ordered parameter values.</param>
    /// <returns>Number of affected rows.</returns>
    procedure Execute(SourceCode: Code[20]; SQL: Text; Parameters: JsonArray): Integer
    var
        Reader: Codeunit "ODBC Reader ori";
        Response: JsonObject;
        Token: JsonToken;
    begin
        Call(SourceCode, 'Execute', SQL, Parameters, Response, Reader, 0);
        Response.Get('affectedRows', Token);
        exit(Token.AsValue().AsInteger());
    end;

    /// <summary>Tests the connection and returns the driver and DBMS identity.</summary>
    /// <param name="SourceCode">Configured source.</param>
    /// <param name="DriverName">Driver reported by the agent.</param>
    /// <param name="DbmsName">DBMS name reported by the agent.</param>
    /// <param name="DbmsVersion">DBMS version reported by the agent.</param>
    procedure TestConnection(SourceCode: Code[20]; var DriverName: Text; var DbmsName: Text; var DbmsVersion: Text)
    var
        Reader: Codeunit "ODBC Reader ori";
        Parameters: JsonArray;
        Response: JsonObject;
    begin
        Clear(DriverName);
        Clear(DbmsName);
        Clear(DbmsVersion);
        Call(SourceCode, 'TestConnection', '', Parameters, Response, Reader, 0);
        DriverName := Response.GetText('driverName');
        DbmsName := Response.GetText('dbmsName');
        DbmsVersion := Response.GetText('dbmsVersion');
    end;

    /// <summary>Returns catalog tables/views and their columns.</summary>
    /// <param name="SourceCode">Configured source.</param>
    /// <param name="ObjectFilter">Catalog object filter passed separately from SQL.</param>
    /// <param name="Result">Array of objects with name, type and columns properties.</param>
    procedure GetSchema(SourceCode: Code[20]; ObjectFilter: Text; var Result: JsonArray)
    var
        Reader: Codeunit "ODBC Reader ori";
        Parameters: JsonArray;
        Response: JsonObject;
    begin
        Clear(Result);
        Call(SourceCode, 'GetSchema', ObjectFilter, Parameters, Response, Reader, 0);
        Result := Response.GetArray('objects');
    end;

    /// <summary>Returns schema together with the database dialect identity.</summary>
    /// <param name="SourceCode">Configured source.</param>
    /// <param name="ObjectFilter">Catalog object filter.</param>
    /// <param name="Result">Catalog objects.</param>
    /// <param name="DbmsName">DBMS reported by the agent, or the last tested identity.</param>
    procedure GetSchema(SourceCode: Code[20]; ObjectFilter: Text; var Result: JsonArray; var DbmsName: Text)
    var
        Source: Record "ODBC Source ori";
        Reader: Codeunit "ODBC Reader ori";
        Parameters: JsonArray;
        Response: JsonObject;
        Token: JsonToken;
    begin
        Clear(Result);
        Clear(DbmsName);
        Call(SourceCode, 'GetSchema', ObjectFilter, Parameters, Response, Reader, 0);
        Result := Response.GetArray('objects');
        if Response.Get('dbmsName', Token) then
            DbmsName := Token.AsValue().AsText()
        else begin
            Source.Get(SourceCode);
            DbmsName := Source."DBMS Name";
        end;
    end;

    local procedure Call(SourceCode: Code[20]; Operation: Text; SQL: Text; Parameters: JsonArray; var Response: JsonObject; var Reader: Codeunit "ODBC Reader ori"; MaxRows: Integer)
    var
        Source: Record "ODBC Source ori";
        SecretMgt: Codeunit "ODBC Secret Mgt ori";
        StartedAt: DateTime;
        Diagnostic: Text;
        Success: Boolean;
        RowCount: Integer;
    begin
        StartedAt := CurrentDateTime();
        ClearLastError();
        Success := TryCall(SourceCode, Operation, SQL, Parameters, Response, Reader, MaxRows);
        if not Success then begin
            if not Source.Get(SourceCode) then
                Source.Init();
            Diagnostic := SecretMgt.Redact(Source, GetLastErrorText());
            if SQL.Trim() <> '' then
                Diagnostic := Diagnostic.Replace(SQL, '[redacted]');
            Clear(Reader);
            Clear(Response);
        end;
        RowCount := Reader.RowCount();
        if Success and (Operation = 'Execute') then
            RowCount := Response.GetInteger('affectedRows');
        LogCall(SourceCode, Operation, RowCount, CurrentDateTime() - StartedAt, Success);
        if not Success then
            Error(Diagnostic);
    end;

    [TryFunction]
    local procedure TryCall(SourceCode: Code[20]; Operation: Text; SQL: Text; Parameters: JsonArray; var Response: JsonObject; var Reader: Codeunit "ODBC Reader ori"; MaxRows: Integer)
    var
        Source: Record "ODBC Source ori";
        Validation: Codeunit "ODBC Setup Validation ori";
        SecretMgt: Codeunit "ODBC Secret Mgt ori";
        Transport: Interface "ODBC Transport ori";
        Request: JsonObject;
        Token: JsonToken;
        EncryptedConnection: SecretText;
        Count: Integer;
        Identity: Text;
    begin
        Validation.ValidateSetup(SourceCode);
        Source.Get(SourceCode);
        if (Operation = 'Execute') and Source."Read Only" then
            Error(ReadOnlyErr, SourceCode);
        if ((Operation = 'Query') or (Operation = 'Execute')) and (SQL.Trim() = '') then
            Error(EmptySqlErr);
        if (Source."Row Cap" < 1) or (Source."Timeout (s)" < 1) then
            Error(InvalidLimitsErr);
        Request.Add('query', '');
        if Operation = 'GetSchema' then
            Request.Add('objectFilter', SQL)
        else
            Request.Replace('query', SQL);
        Request.Add('parameters', Parameters);
        Request.Add('readOnly', Operation <> 'Execute');
        if MaxRows > 0 then
            Source."Row Cap" := MaxRows;
        Request.Add('rowCap', Source."Row Cap");
        Request.Add('timeoutSeconds', Source."Timeout (s)");
        EncryptedConnection := SecretMgt.EncryptConnection(Source);
        Transport := Source.Transport;
        if not TrySend(Transport, Source, Operation, Request, EncryptedConnection, Response) then
            Error(TransportErr, GetLastErrorText());
        if Response.Get('error', Token) then
            if not Token.AsValue().IsNull() then
                if Token.AsValue().AsText() <> '' then
                    Error(AgentErr, Token.AsValue().AsText());
        case Operation of
            'Query':
                Reader.Initialize(Response, Source."Row Cap");
            'Execute':
                begin
                    Count := Response.GetInteger('affectedRows');
                    if Count < 0 then
                        Error(InvalidResponseErr);
                end;
            'TestConnection':
                begin
                    Identity := Response.GetText('driverName');
                    Identity := Response.GetText('dbmsName');
                    Identity := Response.GetText('dbmsVersion');
                    if Identity = '' then
                        Error(InvalidResponseErr);
                end;
            'GetSchema':
                begin
                    Token := Response.GetArray('objects').AsToken();
                    if not Token.IsArray() then
                        Error(InvalidResponseErr);
                end;
        end;
    end;

    [TryFunction]
    local procedure TrySend(Transport: Interface "ODBC Transport ori"; Source: Record "ODBC Source ori"; Operation: Text; Request: JsonObject; EncryptedConnection: SecretText; var Response: JsonObject)
    begin
        Transport.Send(Source, Operation, Request, EncryptedConnection, Response);
    end;

    local procedure LogCall(SourceCode: Code[20]; Operation: Text; RowCount: Integer; Elapsed: Duration; Success: Boolean)
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add('sourceCode', SourceCode);
        Dimensions.Add('operation', Operation);
        Dimensions.Add('rowCount', Format(RowCount, 0, 9));
        Dimensions.Add('durationMs', Format(Elapsed, 0, 9));
        Dimensions.Add('outcome', Format(Success, 0, 9));
        Session.LogMessage('ODBC-0001', 'ODBC call completed', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, Dimensions);
        OnCallCompleted(Dimensions);
    end;

    /// <summary>Exposes the same metadata-only dimensions as the single telemetry event for an ODBC call.</summary>
    /// <param name="Dimensions">Source code, operation, row count, duration and outcome; never SQL or credentials.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCallCompleted(Dimensions: Dictionary of [Text, Text])
    begin
    end;

    var
        ReadOnlyErr: Label 'The ODBC source %1 is read only. Execute is not allowed.', Comment = '%1 = source code; is-IS=ODBC-uppsprettan %1 er eingöngu til lestrar. Execute er ekki leyft.';
        EmptySqlErr: Label 'Enter a non-empty ODBC SQL statement.', Comment = 'is-IS=Sláðu inn ODBC SQL-setningu sem er ekki tóm.';
        InvalidLimitsErr: Label 'The ODBC row cap and timeout must be positive.', Comment = 'is-IS=Hámark ODBC-lína og tímamörk verða að vera jákvæð.';
        TransportErr: Label 'The ODBC transport failed: %1', Comment = '%1 = redacted transport diagnostic; is-IS=ODBC-flutningur mistókst: %1';
        AgentErr: Label 'The ODBC agent reported: %1', Comment = '%1 = redacted agent message; is-IS=ODBC-miðlarinn tilkynnti: %1';
        InvalidResponseErr: Label 'The ODBC agent returned an invalid response.', Comment = 'is-IS=ODBC-miðlarinn skilaði ógildu svari.';
}
