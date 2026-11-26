namespace Origo.Bifrost.ODBC.Test;

using Origo.Bifrost.ODBC;
using System.Security.Encryption;

/// <summary>In-memory agent and telemetry observer. It has no HTTP client and uses only fake fixtures.</summary>
codeunit 98122 "ODBC Mock Transport ori" implements "ODBC Transport ori"
{
    SingleInstance = true;

    /// <summary>Resets all state between tests.</summary>
    procedure Reset()
    begin
        Clear(LastEncryptedConnection);
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
    /// <param name="EncryptedConnection">AES ciphertext retained as SecretText.</param>
    /// <param name="Response">Configured response.</param>
    procedure Send(Source: Record "ODBC Source ori"; Operation: Text; Request: JsonObject; EncryptedConnection: SecretText; var Response: JsonObject)
    begin
        LastEncryptedConnection := EncryptedConnection;
        Calls += 1;
        LastRequest := Request.Clone().AsObject();
        LastOperation := Operation;
        if RaiseFailure then
            Error('Mock failure: Driver={Mock};Server=example.invalid;Password=x-unit-only; MDEyMzQ1Njc4OWFiY2RlZg== fake-relay-key');
        if Source.Code = 'XODBCMCP' then begin
            if not Request.GetBoolean('readOnly') then
                Error('The MCP fixture requires readOnly=true.');
            case Operation of
                'TestConnection':
                    Response.ReadFrom('{"driverName":"Mock ODBC","dbmsName":"MockDB","dbmsVersion":"1.0"}');
                'GetSchema':
                    Response.ReadFrom('{"dbmsName":"MockDB","objects":[{"name":"demo","type":"TABLE","columns":[{"name":"id","type":"INTEGER","nullable":false}]}]}');
                'Query':
                    Response.ReadFrom('{"columns":["id"],"rows":[{"id":7},{"id":8},{"id":9}]}');
                else
                    Error('The MCP fixture supports reads only.');
            end;
            exit;
        end;
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

    /// <summary>Proves the fake fixture connection round-trips through AES without unwrapping any secret.</summary>
    /// <param name="SourceCode">Fake source owning the test key and connection.</param>
    /// <returns>True if the decrypted ciphertext matches the stored fake connection.</returns>
    procedure HasValidEncryptedConnection(SourceCode: Code[20]): Boolean
    var
        Source: Record "ODBC Source ori";
        SecretMgt: Codeunit "ODBC Secret Mgt ori";
        Cipher: Codeunit "Rijndael Cryptography";
        Cryptography: Codeunit "Cryptography Management";
        Decrypted: SecretText;
    begin
        if LastEncryptedConnection.IsEmpty() then
            exit(false);
        Source.Get(SourceCode);
        Cipher.InitRijndaelProvider();
        Cipher.SetEncryptionData(SecretMgt.GetSecret(Source.SystemId, Enum::"ODBC Secret Kind ori"::AesKey), Source."AES Vector");
        Decrypted := Cipher.Decrypt(LastEncryptedConnection);
        exit(Cryptography.GenerateHashAsBase64String('ODBC ciphertext test', Decrypted, 2) =
             Cryptography.GenerateHashAsBase64String('ODBC ciphertext test', SecretMgt.GetSecret(Source.SystemId, Enum::"ODBC Secret Kind ori"::ConnectionString), 2));
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
        LastEncryptedConnection: SecretText;
        LastRequest: JsonObject;
        Reply: JsonObject;
        LastOperation: Text;
        LastDimensions: Dictionary of [Text, Text];
        Calls: Integer;
        Events: Integer;
        RaiseFailure: Boolean;
}
