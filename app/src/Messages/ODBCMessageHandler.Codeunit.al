namespace Origo.Bifrost.ODBC;

using Origo.Bifrost;

/// <summary>Validates agent requests before transport and returns only redacted, typed read results.</summary>
codeunit 10035521 "ODBC Message Handler ori"
{
    Access = Internal;
    Permissions = tabledata "ODBC Source ori" = rm;

    /// <summary>Executes an ODBC read contract after Foundation licence validation.</summary>
    /// <param name="MessageType">One of the four registered read types.</param>
    /// <param name="Argument">Request and response envelope.</param>
    [InherentPermissions(PermissionObjectType::TableData, Database::"ODBC Source ori", 'm')]
    procedure Execute(MessageType: Enum "Message Type ori"; var Argument: Record "Message Argument ori")
    var
        Source: Record "ODBC Source ori";
        Request: JsonObject;
        Response: JsonObject;
        SourceText: Text;
        Token: JsonToken;
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
        if not TryExecute(MessageType, Source, Request, Response) then begin
            // Untrusted transport diagnostics and request values never enter the message error or log.
            ClearLastError();
            Refuse(Argument, Enum::"Bifrost Error Code ori"::PreconditionFailed, '', FailedLbl, CheckSetupLbl);
            exit;
        end;
        if Response.Contains('invalidParameter') then begin
            Refuse(Argument, Enum::"Bifrost Error Code ori"::InvalidParameter, Response.GetText('invalidParameter'), InvalidRequestLbl, ReadContractLbl);
            exit;
        end;
        if MessageType = MessageType::"ODBC.Source.Test" then begin
            Source."Driver Name" := CopyStr(Response.GetText('driverName'), 1, MaxStrLen(Source."Driver Name"));
            Source."DBMS Name" := CopyStr(Response.GetText('dbmsName'), 1, MaxStrLen(Source."DBMS Name"));
            Source.Modify();
        end;
        Argument.SetResponseJson(Response);
        Argument."Content Type" := Argument.GetContentTypeJson();
    end;

    [TryFunction]
    local procedure TryExecute(MessageType: Enum "Message Type ori"; Source: Record "ODBC Source ori"; Request: JsonObject; var Response: JsonObject)
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
        ReadContractLbl: Label 'Read the message contract. Send one SELECT, matching positional parameters and a positive maxRows no greater than the source Row Cap. Comments and statement delimiters are refused.', Comment = 'is-IS=Lestu samning skilaboðanna. Sendu eina SELECT-setningu, samsvarandi stika í röð og jákvætt maxRows sem er ekki hærra en línuhámark uppsprettu. Athugasemdum og setningaskilum er hafnað.';
}
