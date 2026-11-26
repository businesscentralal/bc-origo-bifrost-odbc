namespace Origo.Bifrost.ODBC.Test;

using Origo.Bifrost.ODBC;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

/// <summary>AC01-AC06 through the public AL API in English and Icelandic. All connection data is fake; no network calls.</summary>
codeunit 98120 "ODBC Client Tst ori"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        Assert: Codeunit "Library Assert";
        LowerPermissions: Codeunit "Library - Lower Permissions";
        SecretMgt: Codeunit "ODBC Secret Mgt ori";
        Client: Codeunit "ODBC Client ori";
        Mock: Codeunit "ODBC Mock Transport ori";
        FakeConnectionLbl: Label 'Driver={Mock};Server=example.invalid;Password=x-unit-only;', Locked = true;
        FakeKeyLbl: Label 'MDEyMzQ1Njc4OWFiY2RlZg==', Locked = true;
        OriginalLanguage: Integer;
        FakeValue: Text;
        FakeKey: SecretText;
        FakeConnection: SecretText;
        FakeRelay: SecretText;

    /// <summary>AC01 Query in English.</summary>
    [Test]
    procedure Scenario_AC01_Query_English()
    begin
        VerifyQuery(1033);
    end;

    /// <summary>AC01 Query in Icelandic.</summary>
    [Test]
    procedure Scenario_AC01_Query_Icelandic()
    begin
        VerifyQuery(1039);
    end;

    /// <summary>AC01 ReaderBoundaries in English.</summary>
    [Test]
    procedure Scenario_AC01_ReaderBoundaries_English()
    begin
        VerifyReaderBoundaries(1033);
    end;

    /// <summary>AC01 ReaderBoundaries in Icelandic.</summary>
    [Test]
    procedure Scenario_AC01_ReaderBoundaries_Icelandic()
    begin
        VerifyReaderBoundaries(1039);
    end;

    /// <summary>AC02 ReadOnly in English.</summary>
    [Test]
    procedure Scenario_AC02_ReadOnly_English()
    begin
        VerifyReadOnly(1033);
    end;

    /// <summary>AC02 ReadOnly in Icelandic.</summary>
    [Test]
    procedure Scenario_AC02_ReadOnly_Icelandic()
    begin
        VerifyReadOnly(1039);
    end;

    /// <summary>AC02 Execute in English.</summary>
    [Test]
    procedure Scenario_AC02_Execute_English()
    begin
        VerifyExecute(1033);
    end;

    /// <summary>AC02 Execute in Icelandic.</summary>
    [Test]
    procedure Scenario_AC02_Execute_Icelandic()
    begin
        VerifyExecute(1039);
    end;

    /// <summary>AC03 RowCap in English.</summary>
    [Test]
    procedure Scenario_AC03_RowCap_English()
    begin
        VerifyRowCap(1033);
    end;

    /// <summary>AC03 RowCap in Icelandic.</summary>
    [Test]
    procedure Scenario_AC03_RowCap_Icelandic()
    begin
        VerifyRowCap(1039);
    end;

    /// <summary>AC03 EmptyRows in English.</summary>
    [Test]
    procedure Scenario_AC03_EmptyRows_English()
    begin
        VerifyEmptyRows(1033);
    end;

    /// <summary>AC03 EmptyRows in Icelandic.</summary>
    [Test]
    procedure Scenario_AC03_EmptyRows_Icelandic()
    begin
        VerifyEmptyRows(1039);
    end;

    /// <summary>AC04 Connection in English.</summary>
    [Test]
    procedure Scenario_AC04_Connection_English()
    begin
        VerifyConnection(1033);
    end;

    /// <summary>AC04 Connection in Icelandic.</summary>
    [Test]
    procedure Scenario_AC04_Connection_Icelandic()
    begin
        VerifyConnection(1039);
    end;

    /// <summary>AC04 Schema in English.</summary>
    [Test]
    procedure Scenario_AC04_Schema_English()
    begin
        VerifySchema(1033);
    end;

    /// <summary>AC04 Schema in Icelandic.</summary>
    [Test]
    procedure Scenario_AC04_Schema_Icelandic()
    begin
        VerifySchema(1039);
    end;

    /// <summary>AC05 Blocked in English.</summary>
    [Test]
    procedure Scenario_AC05_Blocked_English()
    begin
        VerifyBlocked(1033);
    end;

    /// <summary>AC05 Blocked in Icelandic.</summary>
    [Test]
    procedure Scenario_AC05_Blocked_Icelandic()
    begin
        VerifyBlocked(1039);
    end;

    /// <summary>AC05 MissingSecret in English.</summary>
    [Test]
    procedure Scenario_AC05_MissingSecret_English()
    begin
        VerifyMissingSecret(1033);
    end;

    /// <summary>AC05 MissingSecret in Icelandic.</summary>
    [Test]
    procedure Scenario_AC05_MissingSecret_Icelandic()
    begin
        VerifyMissingSecret(1039);
    end;

    /// <summary>AC05 TransportFailure in English.</summary>
    [Test]
    procedure Scenario_AC05_TransportFailure_English()
    begin
        VerifyTransportFailure(1033);
    end;

    /// <summary>AC05 TransportFailure in Icelandic.</summary>
    [Test]
    procedure Scenario_AC05_TransportFailure_Icelandic()
    begin
        VerifyTransportFailure(1039);
    end;

    /// <summary>AC05 AgentFailure in English.</summary>
    [Test]
    procedure Scenario_AC05_AgentFailure_English()
    begin
        VerifyAgentFailure(1033);
    end;

    /// <summary>AC05 AgentFailure in Icelandic.</summary>
    [Test]
    procedure Scenario_AC05_AgentFailure_Icelandic()
    begin
        VerifyAgentFailure(1039);
    end;

    /// <summary>AC05 InvalidInput in English.</summary>
    [Test]
    procedure Scenario_AC05_InvalidInput_English()
    begin
        VerifyInvalidInput(1033);
    end;

    /// <summary>AC05 InvalidInput in Icelandic.</summary>
    [Test]
    procedure Scenario_AC05_InvalidInput_Icelandic()
    begin
        VerifyInvalidInput(1039);
    end;

    /// <summary>AC05 MalformedResponse in English.</summary>
    [Test]
    procedure Scenario_AC05_MalformedResponse_English()
    begin
        VerifyMalformedResponse(1033);
    end;

    /// <summary>AC05 MalformedResponse in Icelandic.</summary>
    [Test]
    procedure Scenario_AC05_MalformedResponse_Icelandic()
    begin
        VerifyMalformedResponse(1039);
    end;

    /// <summary>AC05 bounded diagnostic redaction in English.</summary>
    [Test]
    procedure Scenario_AC05_DiagnosticBounds_English()
    begin
        VerifyDiagnosticBounds(1033);
    end;

    /// <summary>AC05 bounded diagnostic redaction in Icelandic.</summary>
    [Test]
    procedure Scenario_AC05_DiagnosticBounds_Icelandic()
    begin
        VerifyDiagnosticBounds(1039);
    end;

    local procedure VerifyDiagnosticBounds(LanguageId: Integer)
    var
        Source: Record "ODBC Source ori";
        Message: Text;
        Result: Text;
    begin
        // [SCENARIO] AC05: bounded matching includes punctuation and never truncates a longer secret.
        Initialize(LanguageId);
        Source.Get('XODBCAPI');
        Message := PadStr('', 256 - StrLen(FakeConnectionLbl), 'x') + FakeConnectionLbl;
        Result := SecretMgt.Redact(Source, Message);
        AssertNoSecrets(Result);
        Assert.IsTrue(Result.EndsWith('[redacted]'), 'Secret at the exact diagnostic boundary');
        Message := PadStr('', 257, 'x') + FakeConnectionLbl;
        Result := SecretMgt.Redact(Source, Message);
        AssertNoSecrets(Result);
        Assert.IsFalse(Result.Contains('xxx'), 'Oversized diagnostic is replaced, never truncated');
        Result := SecretMgt.Redact(Source, 'Connection rejected: Password=not-a-real-password');
        Assert.IsFalse(Result.Contains('Password='), 'Partial connection field is not surfaced');
        Cleanup();
    end;

    local procedure VerifyQuery(LanguageId: Integer)
    var
        Reader: Codeunit "ODBC Reader ori";
        Parameters: JsonArray;
        Request: JsonObject;
        SQL: Text;
        ActualParameters: Text;
        ExpectedParameters: Text;
        Columns: List of [Text];
    begin
        // [SCENARIO] AC01: typed values and positional parameters pass through the public API.
        Initialize(LanguageId);
        Mock.SetResponse('{"rows":[{"id":7,"amount":1.25,"active":true,"name":"Alice","day":"2026-11-26","stamp":"2026-11-26T12:00:00Z","empty":null}]}');
        SQL := 'select * from demo where name = ? and id = ?';
        Parameters.Add('x'' OR 1=1 --');
        Parameters.Add(42);
        Parameters.WriteTo(ExpectedParameters);
        Client.Query('XODBCAPI', SQL, Parameters, Reader);
        Assert.AreEqual(1, Mock.GetRequest(Request), 'One transport invocation');
        Assert.AreEqual(SQL, Request.GetText('query'), 'Parameters never enter SQL');
        Request.GetArray('parameters').WriteTo(ActualParameters);
        Assert.AreEqual(ExpectedParameters, ActualParameters, 'Parameter order and values');
        Assert.IsFalse(Request.Contains('dbConnectionString'), 'Secret connection data is separate from diagnostic JSON');
        Assert.IsTrue(Mock.HasValidEncryptedConnection('XODBCAPI'), 'Encrypted connection provided as SecretText');
        AssertLimits(Request, true);
        Assert.IsTrue(Reader.Read(), 'First row');
        Assert.AreEqual(7, Reader.GetInteger('id'), 'Integer');
        Assert.AreEqual(1.25, Reader.GetDecimal('amount'), 'Decimal');
        Assert.IsTrue(Reader.GetBoolean('active'), 'Boolean');
        Assert.AreEqual('Alice', Reader.GetText('name'), 'Text');
        Assert.AreEqual(20261126D, Reader.GetDate('day'), 'Date');
        Assert.AreEqual(CreateDateTime(20261126D, 120000T), Reader.GetDateTime('stamp'), 'DateTime');
        Assert.IsTrue(Reader.IsNull('empty'), 'SQL NULL');
        Columns := Reader.GetColumns();
        Assert.AreEqual(7, Columns.Count(), 'Column names');
        AssertTelemetry(true, 1);
        Cleanup();
    end;

    local procedure VerifyReaderBoundaries(LanguageId: Integer)
    var
        Reader: Codeunit "ODBC Reader ori";
        Parameters: JsonArray;
    begin
        // [SCENARIO] AC01: getters reject an unpositioned, exhausted, missing or null value.
        Initialize(LanguageId);
        Mock.SetResponse('{"rows":[{"id":7,"empty":null}]}');
        Client.Query('XODBCAPI', 'select id', Parameters, Reader);
        asserterror Reader.GetInteger('id');
        Assert.IsTrue(Reader.Read(), 'Positioned');
        asserterror Reader.GetText('missing');
        asserterror Reader.GetInteger('empty');
        Assert.IsFalse(Reader.Read(), 'EOF');
        asserterror Reader.GetInteger('id');
        Cleanup();
    end;

    local procedure VerifyReadOnly(LanguageId: Integer)
    var
        Parameters: JsonArray;
        Request: JsonObject;
    begin
        // [SCENARIO] AC02: refusal happens before the mock receives a request.
        Initialize(LanguageId);
        asserterror Client.Execute('XODBCAPI', 'update demo set id = ?', Parameters);
        AssertClearError(LanguageId, 'read only', 'eingöngu til lestrar');
        Assert.AreEqual(0, Mock.GetRequest(Request), 'Read-only refusal before transport');
        AssertTelemetry(false, 0);
        Cleanup();
    end;

    local procedure VerifyExecute(LanguageId: Integer)
    var
        Source: Record "ODBC Source ori";
        Parameters: JsonArray;
        Request: JsonObject;
    begin
        // [SCENARIO] AC02/AC03: only explicitly writable Execute sends readOnly=false.
        Initialize(LanguageId);
        Source.Get('XODBCAPI');
        Source."Read Only" := false;
        Source.Modify();
        Mock.SetResponse('{"affectedRows":3}');
        Parameters.Add(9);
        Assert.AreEqual(3, Client.Execute('XODBCAPI', 'update demo set id = ?', Parameters), 'Affected rows');
        Assert.AreEqual(1, Mock.GetRequest(Request), 'Transport invocation');
        AssertLimits(Request, false);
        Assert.AreEqual(9, Request.GetArray('parameters').GetInteger(0), 'Execute parameter');
        AssertTelemetry(true, 3);
        Cleanup();
    end;

    local procedure VerifyRowCap(LanguageId: Integer)
    var
        Reader: Codeunit "ODBC Reader ori";
        Parameters: JsonArray;
        Request: JsonObject;
    begin
        // [SCENARIO] AC03: exact boundary retains all rows; one above truncates locally.
        Initialize(LanguageId);
        Mock.SetResponse('{"rows":[{"id":1},{"id":2}]}');
        Client.Query('XODBCAPI', 'select id', Parameters, Reader);
        Assert.AreEqual(2, Reader.RowCount(), 'Exact cap');
        Assert.IsFalse(Reader.IsTruncated(), 'Exact cap is complete');
        Mock.Reset();
        Mock.SetResponse('{"rows":[{"id":1},{"id":2},{"id":3}]}');
        Client.Query('XODBCAPI', 'select id', Parameters, Reader);
        Assert.AreEqual(2, Reader.RowCount(), 'One above cap');
        Assert.IsTrue(Reader.IsTruncated(), 'BC truncation flag');
        Mock.GetRequest(Request);
        AssertLimits(Request, true);
        Assert.IsTrue(Reader.Read(), 'Row 1');
        Assert.IsTrue(Reader.Read(), 'Row 2');
        Assert.IsFalse(Reader.Read(), 'Row 3 omitted');
        AssertTelemetry(true, 2);
        Cleanup();
    end;

    local procedure VerifyEmptyRows(LanguageId: Integer)
    var
        Reader: Codeunit "ODBC Reader ori";
        Parameters: JsonArray;
        Columns: List of [Text];
    begin
        // [SCENARIO] AC01/AC03: empty rows preserve metadata and an agent truncation flag.
        Initialize(LanguageId);
        Mock.SetResponse('{"rows":[],"columns":["id"],"truncated":true}');
        Client.Query('XODBCAPI', 'select id', Parameters, Reader);
        Assert.AreEqual(0, Reader.RowCount(), 'Empty');
        Assert.IsFalse(Reader.Read(), 'No current row');
        Assert.IsTrue(Reader.IsTruncated(), 'Agent flag preserved');
        Columns := Reader.GetColumns();
        Assert.AreEqual('id', Columns.Get(1), 'Empty result metadata');
        Cleanup();
    end;

    local procedure VerifyConnection(LanguageId: Integer)
    var
        Source: Record "ODBC Source ori";
        Request: JsonObject;
        Driver: Text;
        Dbms: Text;
        Version: Text;
    begin
        // [SCENARIO] AC04/AC03: identity comes from the mock, reads stay read-only even on a writable source.
        Initialize(LanguageId);
        Source.Get('XODBCAPI');
        Source."Read Only" := false;
        Source.Modify();
        Mock.SetResponse('{"driverName":"Mock ODBC","dbmsName":"MockDB","dbmsVersion":"1.0"}');
        Client.TestConnection('XODBCAPI', Driver, Dbms, Version);
        Assert.AreEqual('Mock ODBC', Driver, 'Driver');
        Assert.AreEqual('MockDB', Dbms, 'DBMS');
        Assert.AreEqual('1.0', Version, 'Version');
        Mock.GetRequest(Request);
        AssertLimits(Request, true);
        AssertTelemetry(true, 0);
        Cleanup();
    end;

    local procedure VerifySchema(LanguageId: Integer)
    var
        Request: JsonObject;
        Result: JsonArray;
        Token: JsonToken;
    begin
        // [SCENARIO] AC04/AC03: catalog filter is distinct from query and nested columns survive.
        Initialize(LanguageId);
        Mock.SetResponse('{"objects":[{"name":"demo","type":"TABLE","columns":[{"name":"id","type":"INTEGER"}]}]}');
        Client.GetSchema('XODBCAPI', 'dem%', Result);
        Assert.AreEqual(1, Result.Count(), 'One table');
        Result.Get(0, Token);
        Assert.AreEqual('demo', Token.AsObject().GetText('name'), 'Table');
        Assert.AreEqual(1, Token.AsObject().GetArray('columns').Count(), 'Columns');
        Mock.GetRequest(Request);
        Assert.AreEqual('dem%', Request.GetText('objectFilter'), 'Catalog filter');
        Assert.AreEqual('', Request.GetText('query'), 'Not SQL');
        AssertLimits(Request, true);
        AssertTelemetry(true, 0);
        Cleanup();
    end;

    local procedure VerifyBlocked(LanguageId: Integer)
    var
        Source: Record "ODBC Source ori";
        Reader: Codeunit "ODBC Reader ori";
        Parameters: JsonArray;
        Request: JsonObject;
    begin
        // [SCENARIO] AC05: blocked source is localized and never reaches transport.
        Initialize(LanguageId);
        Source.Get('XODBCAPI');
        Source.Blocked := true;
        Source.Modify();
        asserterror Client.Query('XODBCAPI', 'select id', Parameters, Reader);
        AssertClearError(LanguageId, 'blocked', 'læst');
        Assert.AreEqual(0, Mock.GetRequest(Request), 'No transport');
        AssertTelemetry(false, 0);
        Cleanup();
    end;

    local procedure VerifyMissingSecret(LanguageId: Integer)
    var
        Source: Record "ODBC Source ori";
        Reader: Codeunit "ODBC Reader ori";
        Parameters: JsonArray;
        Request: JsonObject;
    begin
        // [SCENARIO] AC05: missing secret is localized and never reaches transport.
        Initialize(LanguageId);
        Source.Get('XODBCAPI');
        SecretMgt.DeleteSecret(Source.SystemId, Enum::"ODBC Secret Kind ori"::ConnectionString);
        asserterror Client.Query('XODBCAPI', 'select id', Parameters, Reader);
        AssertClearError(LanguageId, 'missing the secret', 'vantar leyndarmálið');
        Assert.AreEqual(0, Mock.GetRequest(Request), 'No transport');
        AssertTelemetry(false, 0);
        Cleanup();
    end;

    local procedure VerifyTransportFailure(LanguageId: Integer)
    var
        Reader: Codeunit "ODBC Reader ori";
        Parameters: JsonArray;
    begin
        // [SCENARIO] AC05: even a failing transport echoing fake secrets cannot expose them.
        Initialize(LanguageId);
        Mock.Fail();
        asserterror Client.Query('XODBCAPI', 'select id', Parameters, Reader);
        AssertNoSecrets(GetLastErrorText());
        AssertClearError(LanguageId, 'transport failed', 'flutningur mistókst');
        Assert.IsTrue(GetLastErrorText().Contains('Mock failure'), 'Diagnostic survives redaction');
        AssertTelemetry(false, 0);
        Assert.AreEqual(0, Reader.RowCount(), 'Failed query clears reader');
        Cleanup();
    end;

    local procedure VerifyAgentFailure(LanguageId: Integer)
    var
        Reader: Codeunit "ODBC Reader ori";
        Parameters: JsonArray;
    begin
        // [SCENARIO] AC05: localized wrapper preserves agent message with secrets removed.
        Initialize(LanguageId);
        Mock.SetResponse('{"error":"Catalog denied: Driver={Mock};Server=example.invalid;Password=x-unit-only; MDEyMzQ1Njc4OWFiY2RlZg== fake-relay-key"}');
        asserterror Client.Query('XODBCAPI', 'select id', Parameters, Reader);
        AssertClearError(LanguageId, 'agent reported', 'miðlarinn tilkynnti');
        AssertNoSecrets(GetLastErrorText());
        Assert.IsTrue(GetLastErrorText().Contains('Catalog denied'), 'Agent message retained');
        AssertTelemetry(false, 0);
        Cleanup();
    end;

    local procedure VerifyInvalidInput(LanguageId: Integer)
    var
        Source: Record "ODBC Source ori";
        Reader: Codeunit "ODBC Reader ori";
        Parameters: JsonArray;
        Request: JsonObject;
    begin
        // [SCENARIO] AC05/AC06: empty SQL, missing source and zero limits fail before transport.
        Initialize(LanguageId);
        asserterror Client.Query('XODBCAPI', ' ', Parameters, Reader);
        AssertClearError(LanguageId, 'non-empty', 'ekki tóm');
        Cleanup();
        Initialize(LanguageId);
        asserterror Client.Query('XNOTFOUND', 'select id', Parameters, Reader);
        AssertClearError(LanguageId, 'does not exist', 'ekki til');
        Cleanup();
        Initialize(LanguageId);
        Source.Get('XODBCAPI');
        Source."Row Cap" := 0;
        Source.Modify();
        asserterror Client.Query('XODBCAPI', 'select id', Parameters, Reader);
        AssertClearError(LanguageId, 'must be positive', 'verða að vera jákvæð');
        Assert.AreEqual(0, Mock.GetRequest(Request), 'Invalid input is never transported');
        Cleanup();
        Initialize(LanguageId);
        Source.Get('XODBCAPI');
        Source."Timeout (s)" := 0;
        Source.Modify();
        asserterror Client.Query('XODBCAPI', 'select id', Parameters, Reader);
        AssertClearError(LanguageId, 'must be positive', 'verða að vera jákvæð');
        Assert.AreEqual(0, Mock.GetRequest(Request), 'Zero timeout is never transported');
        Cleanup();
    end;

    local procedure VerifyMalformedResponse(LanguageId: Integer)
    var
        Reader: Codeunit "ODBC Reader ori";
        Parameters: JsonArray;
    begin
        // [SCENARIO] AC05: invalid row shape is refused and does not leave stale reader data.
        Initialize(LanguageId);
        Mock.SetResponse('{"rows":[{"id":1}]}');
        Client.Query('XODBCAPI', 'select id', Parameters, Reader);
        Mock.Reset();
        Mock.SetResponse('{"rows":[42]}');
        asserterror Client.Query('XODBCAPI', 'select id', Parameters, Reader);
        AssertClearError(LanguageId, 'invalid row result', 'ógildri línuniðurstöðu');
        Assert.AreEqual(0, Reader.RowCount(), 'No stale rows');
        AssertTelemetry(false, 0);
        Cleanup();
    end;

    local procedure Initialize(LanguageId: Integer)
    var
        Source: Record "ODBC Source ori";
        Relay: Record "ODBC Relay Connection ori";
    begin
        FakeValue := FakeKeyLbl;
        FakeKey := FakeValue;
        FakeValue := FakeConnectionLbl;
        FakeConnection := FakeValue;
        FakeValue := 'fake-relay-key';
        FakeRelay := FakeValue;
        OriginalLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        LowerPermissions.SetExactPermissionSet('ODBC Setup Test ori');
        CleanupRecords();
        Mock.Reset();
        Relay.Code := 'XODBCAPI';
        Relay."Relay Namespace" := 'unit.invalid';
        Relay."Hybrid Connection Name" := 'mock';
        Relay."SAS Key Name" := 'mock';
        Relay.Insert(true);
        SecretMgt.SetSecret(Relay.SystemId, Enum::"ODBC Secret Kind ori"::RelaySasKey, FakeRelay);
        Source.Init();
        Source.Code := 'XODBCAPI';
        Source."Relay Connection Code" := Relay.Code;
        Source."AES Vector" := FakeKeyLbl;
        Source.Transport := Source.Transport::Mock;
        Source."Row Cap" := 2;
        Source."Timeout (s)" := 17;
        Source.Insert(true);
        SecretMgt.SetSecret(Source.SystemId, Enum::"ODBC Secret Kind ori"::AesKey, FakeKey);
        SecretMgt.SetSecret(Source.SystemId, Enum::"ODBC Secret Kind ori"::ConnectionString, FakeConnection);
    end;

    local procedure Cleanup()
    begin
        CleanupRecords();
        Mock.Reset();
        GlobalLanguage(OriginalLanguage);
    end;

    local procedure CleanupRecords()
    var
        Source: Record "ODBC Source ori";
        Relay: Record "ODBC Relay Connection ori";
    begin
        if Source.Get('XODBCAPI') then
            Source.Delete(true);
        if Relay.Get('XODBCAPI') then
            Relay.Delete(true);
    end;

    local procedure AssertLimits(Request: JsonObject; ReadOnly: Boolean)
    begin
        Assert.AreEqual(2, Request.GetInteger('rowCap'), 'Row cap');
        Assert.AreEqual(17, Request.GetInteger('timeoutSeconds'), 'Timeout');
        Assert.AreEqual(ReadOnly, Request.GetBoolean('readOnly'), 'Read-only flag');
    end;

    local procedure AssertClearError(LanguageId: Integer; English: Text; Icelandic: Text)
    begin
        AssertNoSecrets(GetLastErrorText());
        if LanguageId = 1039 then
            Assert.IsTrue(GetLastErrorText().Contains(Icelandic), 'Icelandic error: ' + GetLastErrorText())
        else
            Assert.IsTrue(GetLastErrorText().Contains(English), 'English error: ' + GetLastErrorText());
    end;

    local procedure AssertNoSecrets(Value: Text)
    begin
        Assert.IsFalse(Value.Contains(FakeConnectionLbl), 'Connection string must be redacted');
        Assert.IsFalse(Value.Contains(FakeKeyLbl), 'AES key must be redacted');
        Assert.IsFalse(Value.Contains('fake-relay-key'), 'Relay key must be redacted');
    end;

    local procedure AssertTelemetry(Success: Boolean; RowCount: Integer)
    var
        Dimensions: Dictionary of [Text, Text];
        Name: Text;
        Value: Text;
    begin
        Assert.AreEqual(1, Mock.GetTelemetry(Dimensions), 'Exactly one telemetry event per call');
        Assert.AreEqual(5, Dimensions.Count(), 'Only approved metadata fields');
        Assert.AreEqual('XODBCAPI', Dimensions.Get('sourceCode'), 'Source dimension');
        Assert.AreEqual(Format(Success, 0, 9), Dimensions.Get('outcome'), 'Outcome dimension');
        Assert.AreEqual(Format(RowCount, 0, 9), Dimensions.Get('rowCount'), 'Count dimension');
        foreach Name in Dimensions.Keys() do begin
            Value := Dimensions.Get(Name);
            AssertNoSecrets(Value);
            Assert.IsFalse(Value.Contains('select'), 'SQL never enters telemetry');
        end;
    end;
}
