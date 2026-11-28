namespace Origo.Bifrost.ODBC;

using Origo.Bifrost;
using System.Utilities;

/// <summary>Validates agent requests before transport and returns only redacted, typed read results.</summary>
codeunit 10035521 "ODBC Message Handler ori"
{
    Access = Internal;

    /// <summary>Executes an ODBC read contract after Foundation licence validation.</summary>
    /// <param name="MessageType">One of the four registered read types.</param>
    /// <param name="Argument">Request and response envelope.</param>
    procedure Execute(MessageType: Enum "Message Type ori"; var Argument: Record "Message Argument ori")
    var
        Source: Record "ODBC Source ori";
        Request: JsonObject;
        Response: JsonObject;
        SourceText: Text;
        Token: JsonToken;
        StageRequested: Boolean;
    begin
        Request := Argument.GetRequestJson();
        Argument.RedactRequestData();
        // Foundation checks parameter names after execution. Keep its temporary argument accurate;
        // SetRequestJson does not restore the persisted Message request that was just redacted.
        Argument.SetRequestJson(Request);
        if MessageType <> MessageType::"ODBC.Source.List" then begin
            if not Request.Get('source', Token) then begin
                Refuse(Argument, Enum::"Bifrost Error Code ori"::MissingParameter, 'source', SourceRequiredLbl, SelectSourceLbl);
                exit;
            end;
            if not ReadString(Token, SourceText) then begin
                Refuse(Argument, Enum::"Bifrost Error Code ori"::InvalidParameterFormat, 'source', SourceRequiredLbl, SelectSourceLbl);
                exit;
            end;
            if (SourceText = '') or (StrLen(SourceText) > MaxStrLen(Source.Code)) then begin
                Refuse(Argument, Enum::"Bifrost Error Code ori"::InvalidParameter, 'source', SourceRequiredLbl, SelectSourceLbl);
                exit;
            end;
            if not Source.Get(SourceText) then begin
                Refuse(Argument, Enum::"Bifrost Error Code ori"::RecordNotFound, 'source', SourceMissingLbl, SelectSourceLbl);
                exit;
            end;
            if Source.Blocked then begin
                Refuse(Argument, Enum::"Bifrost Error Code ori"::PreconditionFailed, 'source', SourceBlockedLbl, UnblockLbl);
                exit;
            end;
        end;
        if not TryExecute(MessageType, Source, Request, Response, StageRequested) then begin
            // Untrusted transport diagnostics and request values never enter the message error or log.
            ClearLastError();
            Refuse(Argument, Enum::"Bifrost Error Code ori"::PreconditionFailed, '', FailedLbl, CheckSetupLbl);
            exit;
        end;
        if Response.Contains('invalidParameter') then begin
            Refuse(Argument, Enum::"Bifrost Error Code ori"::InvalidParameter, Response.GetText('invalidParameter'), InvalidRequestLbl, ReadContractLbl);
            exit;
        end;
        if MessageType = MessageType::"ODBC.Source.Test" then
            CacheIdentity(Source, Response);
        if MessageType = MessageType::"ODBC.Query.Run" then
            if not ApplyOutput(Source, StageRequested, Response, Argument) then
                exit;
        Argument.SetResponseJson(Response);
        Argument."Content Type" := Argument.GetContentTypeJson();
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"ODBC Source ori", 'M', InherentPermissionsScope::Both)]
    local procedure CacheIdentity(var Source: Record "ODBC Source ori"; Response: JsonObject)
    begin
        Source."Driver Name" := CopyStr(Response.GetText('driverName'), 1, MaxStrLen(Source."Driver Name"));
        Source."DBMS Name" := CopyStr(Response.GetText('dbmsName'), 1, MaxStrLen(Source."DBMS Name"));
        Source.Modify();
    end;

    /// <summary>Returns the result inline, or stores it as one Blob Staging row when staging was requested or the inline limit is exceeded.</summary>
    /// <returns>False when the result exceeds the staging cap and an error was returned.</returns>
    local procedure ApplyOutput(Source: Record "ODBC Source ori"; StageRequested: Boolean; var Response: JsonObject; var Argument: Record "Message Argument ori"): Boolean
    var
        BlobStaging: Codeunit "Blob Staging ori";
        TempBlob: Codeunit "Temp Blob";
        Content: JsonObject;
        Staged: JsonObject;
        OutStr: OutStream;
        InStr: InStream;
        ContentText: Text;
        FileName: Text;
        ByteSize: BigInteger;
        LimitBytes: BigInteger;
        MaxBytes: BigInteger;
        StagingId: Guid;
    begin
        Content.Add('columns', Response.GetArray('columns'));
        Content.Add('rows', Response.GetArray('rows'));
        Content.WriteTo(ContentText);
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(ContentText);
        ByteSize := TempBlob.Length();
        LimitBytes := InlineLimitBytes(Source);
        if (not StageRequested) and (ByteSize <= LimitBytes) then begin
            Response.Add('staged', false);
            exit(true);
        end;
        MaxBytes := MaxStagedBytes();
        if ByteSize > MaxBytes then begin
            Refuse(Argument, Enum::"Bifrost Error Code ori"::LimitExceeded, 'maxRows', StrSubstNo(TooLargeErr, ByteSize, MaxBytes), TooLargeNextStepLbl);
            exit(false);
        end;
        FileName := Source.Code + '-' + Format(CurrentDateTime(), 0, '<Year4><Month,2><Day,2><Hours24,2><Minutes,2><Seconds,2>') + '.json';
        TempBlob.CreateInStream(InStr);
        StagingId := BlobStaging.Create(InStr, FileName, StagedContentTypeTok, StagingSourceTok);
        Staged.Add('status', 'Success');
        Staged.Add('staged', true);
        Staged.Add('stagingId', Format(StagingId, 0, 4).ToLower());
        Staged.Add('rowCount', Response.GetInteger('rowCount'));
        Staged.Add('columns', Response.GetArray('columns'));
        Staged.Add('contentType', StagedContentTypeTok);
        Staged.Add('byteSize', ByteSize);
        Staged.Add('truncated', Response.GetBoolean('truncated'));
        Response := Staged;
        exit(true);
    end;

    /// <summary>Inline limit in bytes from the source; unset or out-of-range values fall back to the 1 MB default or the 15 MB maximum.</summary>
    local procedure InlineLimitBytes(Source: Record "ODBC Source ori"): BigInteger
    var
        LimitKB: Integer;
    begin
        LimitKB := Source."Inline Result Limit (KB)";
        if LimitKB < 1 then
            LimitKB := 1024;
        if LimitKB > 15360 then
            LimitKB := 15360;
        exit(LimitKB * 1024);
    end;

    /// <summary>Largest staged result: the Foundation Blob Staging cap for MCP blobs, 25 MB.</summary>
    local procedure MaxStagedBytes() MaxBytes: BigInteger
    begin
        MaxBytes := 26214400;
        OnGetMaxStagedBytes(MaxBytes);
    end;

    /// <summary>Test seam: lets the test app lower the staging cap without building a 25 MB result.</summary>
    /// <param name="MaxBytes">The staging cap in bytes.</param>
    [InternalEvent(false)]
    local procedure OnGetMaxStagedBytes(var MaxBytes: BigInteger)
    begin
    end;

    [TryFunction]
    local procedure TryExecute(MessageType: Enum "Message Type ori"; Source: Record "ODBC Source ori"; Request: JsonObject; var Response: JsonObject; var StageRequested: Boolean)
    var
        Client: Codeunit "ODBC Client ori";
        Reader: Codeunit "ODBC Reader ori";
        Statement: Codeunit "ODBC Read Statement ori";
        Items: JsonArray;
        Parameters: JsonArray;
        Columns: JsonArray;
        Item: JsonObject;
        Token: JsonToken;
        CleanToken: JsonToken;
        SQL: Text;
        ObjectFilter: Text;
        MaxRowsText: Text;
        Driver: Text;
        Dbms: Text;
        Version: Text;
        Column: Text;
        OutputMode: Text;
        MaxRows: Integer;
        StartedAt: DateTime;
    begin
        Response.Add('status', 'Success');
        case MessageType of
            MessageType::"ODBC.Source.List":
                begin
                    Source.SetLoadFields(Code, Description, "Driver Name", "DBMS Name", "Read Only", Blocked, SystemId, "Relay Connection Code", "Blob Container Code");
                    Source.ReadIsolation := IsolationLevel::ReadCommitted;
                    if Source.FindSet() then
                        repeat
                            Clear(Item);
                            Item.Add('code', SafeText(Source, Source.Code));
                            Item.Add('description', SafeText(Source, Source.Description));
                            Item.Add('driverName', SafeText(Source, Source."Driver Name"));
                            Item.Add('dbmsName', SafeText(Source, Source."DBMS Name"));
                            Item.Add('readOnly', Source."Read Only");
                            Item.Add('blocked', Source.Blocked);
                            Items.Add(Item);
                        until Source.Next() = 0;
                    Response.Add('sources', Items);
                end;
            MessageType::"ODBC.Source.Test":
                begin
                    StartedAt := CurrentDateTime();
                    Client.TestConnection(Source.Code, Driver, Dbms, Version);
                    Response.Add('driverName', SafeText(Source, Driver));
                    Response.Add('dbmsName', SafeText(Source, Dbms));
                    Response.Add('dbmsVersion', SafeText(Source, Version));
                    Response.Add('roundTripMs', CurrentDateTime() - StartedAt);
                end;
            MessageType::"ODBC.Schema.Get":
                begin
                    if Request.Get('objectFilter', Token) then
                        if not ReadString(Token, ObjectFilter) then begin
                            Response.Add('invalidParameter', 'objectFilter');
                            exit;
                        end;
                    Client.GetSchema(Source.Code, ObjectFilter, Items, Dbms);
                    Sanitize(Source, Items.AsToken(), CleanToken);
                    Response.Add('objects', CleanToken);
                    Response.Add('dbmsName', SafeText(Source, Dbms));
                end;
            MessageType::"ODBC.Query.Run":
                begin
                    if not Request.Get('sql', Token) then begin
                        Response.Add('invalidParameter', 'sql');
                        exit;
                    end;
                    if not ReadString(Token, SQL) then begin
                        Response.Add('invalidParameter', 'sql');
                        exit;
                    end;
                    if Request.Get('parameters', Token) then begin
                        if not Token.IsArray() then begin
                            Response.Add('invalidParameter', 'parameters');
                            exit;
                        end;
                        Parameters := Token.AsArray();
                    end;
                    foreach Token in Parameters do
                        if not Token.IsValue() then begin
                            Response.Add('invalidParameter', 'parameters');
                            exit;
                        end;
                    if Request.Get('output', Token) then begin
                        if not ReadString(Token, OutputMode) then begin
                            Response.Add('invalidParameter', 'output');
                            exit;
                        end;
                        case OutputMode of
                            'inline':
                                StageRequested := false;
                            'staged':
                                StageRequested := true;
                            else begin
                                Response.Add('invalidParameter', 'output');
                                exit;
                            end;
                        end;
                    end;
                    if not Statement.IsReadOnly(SQL, Parameters.Count()) then begin
                        Response.Add('invalidParameter', 'sql');
                        exit;
                    end;
                    MaxRows := Source."Row Cap";
                    if Request.Get('maxRows', Token) then begin
                        if not Token.IsValue() then begin
                            Response.Add('invalidParameter', 'maxRows');
                            exit;
                        end;
                        Token.WriteTo(MaxRowsText);
                        if not Evaluate(MaxRows, MaxRowsText, 9) then
                            MaxRows := 0;
                        if (MaxRows < 1) or (MaxRows > Source."Row Cap") then begin
                            Response.Add('invalidParameter', 'maxRows');
                            exit;
                        end;
                    end;
                    Client.Query(Source.Code, SQL, Parameters, MaxRows, Reader);
                    foreach Column in Reader.GetColumns() do
                        Columns.Add(SafeText(Source, Column));
                    while Reader.Read() do begin
                        Sanitize(Source, Reader.GetRowJson().AsToken(), CleanToken);
                        Items.Add(CleanToken);
                    end;
                    Response.Add('columns', Columns);
                    Response.Add('rows', Items);
                    Response.Add('rowCount', Items.Count());
                    Response.Add('truncated', Reader.IsTruncated());
                end;
        end;
    end;

    local procedure Refuse(var Argument: Record "Message Argument ori"; ErrorCode: Enum "Bifrost Error Code ori"; Parameter: Text; Message: Text; NextStep: Text)
    begin
        Argument.RespondWithError(ErrorCode, Message, Parameter, '', '', NextStep);
    end;

    local procedure ReadString(Token: JsonToken; var Value: Text): Boolean
    var
        Serialized: Text;
    begin
        if not Token.IsValue() then
            exit(false);
        Token.WriteTo(Serialized);
        if CopyStr(Serialized, 1, 1) <> '"' then
            exit(false);
        Value := Token.AsValue().AsText();
        exit(true);
    end;

    local procedure SafeText(Source: Record "ODBC Source ori"; Value: Text): Text
    var
        Secrets: Codeunit "ODBC Secret Mgt ori";
    begin
        exit(Secrets.RedactValue(Source, Value));
    end;

    local procedure Sanitize(Source: Record "ODBC Source ori"; Input: JsonToken; var Output: JsonToken)
    var
        ResultObject: JsonObject;
        ResultArray: JsonArray;
        Value: JsonValue;
        Child: JsonToken;
        CleanChild: JsonToken;
        PropertyName: Text;
        TextValue: Text;
    begin
        if Input.IsObject() then begin
            foreach PropertyName in Input.AsObject().Keys() do begin
                Input.AsObject().Get(PropertyName, Child);
                Sanitize(Source, Child, CleanChild);
                ResultObject.Add(SafeText(Source, PropertyName), CleanChild);
            end;
            Output := ResultObject.AsToken();
        end else
            if Input.IsArray() then begin
                foreach Child in Input.AsArray() do begin
                    Sanitize(Source, Child, CleanChild);
                    ResultArray.Add(CleanChild);
                end;
                Output := ResultArray.AsToken();
            end else begin
                Output := Input;
                if ReadString(Input, TextValue) then begin
                    Value.SetValue(SafeText(Source, TextValue));
                    Output := Value.AsToken();
                end;
            end;
    end;

    var
        SourceRequiredLbl: Label 'Send a configured ODBC source code of at most 20 characters.', Comment = 'is-IS=Sendu kóða skilgreindrar ODBC-uppsprettu, að hámarki 20 stafi.';
        SelectSourceLbl: Label 'Use ODBC.Source.List and select an existing source code.', Comment = 'is-IS=Notaðu ODBC.Source.List og veldu kóða fyrirliggjandi uppsprettu.';
        SourceMissingLbl: Label 'The ODBC source does not exist.', Comment = 'is-IS=ODBC-uppsprettan er ekki til.';
        SourceBlockedLbl: Label 'The ODBC source is blocked.', Comment = 'is-IS=ODBC-uppsprettan er læst.';
        UnblockLbl: Label 'Ask an administrator to unblock the source before retrying.', Comment = 'is-IS=Biddu stjórnanda um að aflæsa uppsprettunni áður en reynt er aftur.';
        FailedLbl: Label 'The ODBC read could not be completed.', Comment = 'is-IS=Ekki tókst að ljúka ODBC-lestri.';
        CheckSetupLbl: Label 'Check the source setup and agent availability, then retry.', Comment = 'is-IS=Athugaðu uppsetningu uppsprettu og aðgengi miðlara og reyndu aftur.';
        InvalidRequestLbl: Label 'The ODBC read request is invalid.', Comment = 'is-IS=ODBC-lesbeiðnin er ógild.';
        StagedContentTypeTok: Label 'application/json', Locked = true;
        StagingSourceTok: Label 'ODBC', Locked = true;
        TooLargeErr: Label 'The query result is %1 bytes, which exceeds the Blob Staging limit of %2 bytes.', Comment = '%1 = result size in bytes, %2 = limit in bytes, is-IS=Niðurstaða fyrirspurnarinnar er %1 bæti, sem er yfir %2 bæta hámarki Blob Staging.';
        TooLargeNextStepLbl: Label 'Lower maxRows or filter the SELECT with a WHERE clause or fewer columns, then retry.', Comment = 'is-IS=Lækkaðu maxRows eða síaðu SELECT-setninguna með WHERE-skilyrði eða færri dálkum og reyndu aftur.';
        ReadContractLbl: Label 'Read the message contract. Send one SELECT, matching positional parameters and a positive maxRows no greater than the source Row Cap. Comments and statement delimiters are refused.', Comment = 'is-IS=Lestu samning skilaboðanna. Sendu eina SELECT-setningu, samsvarandi stika í röð og jákvætt maxRows sem er ekki hærra en línuhámark uppsprettu. Athugasemdum og setningaskilum er hafnað.';
}
