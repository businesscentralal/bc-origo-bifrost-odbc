namespace Origo.Bifrost.ODBC;

using Origo.Bifrost;

/// <summary>Public contract chapters for the four queued, licence-metered ODBC read types.</summary>
codeunit 10035522 "ODBC Contract Parts ori"
{
    Access = Internal;

    /// <summary>Declares the queue envelope.</summary>
    procedure Envelope(MessageType: Enum "Message Type ori") Result: JsonObject
    var
        Subject: JsonObject;
        Forms: JsonArray;
    begin
        Subject.Add('use', 'notUsed');
        Subject.Add('forms', Forms);
        Result.Add('subject', Subject);
        Result.Add('dataRequired', MessageType <> MessageType::"ODBC.Source.List");
        Result.Add('version', '1.0');
        Result.Add('contentType', 'text/json');
        Result.Add('endpoint', 'POST /queues');
    end;

    /// <summary>Declares input values under data.</summary>
    procedure Parameters(MessageType: Enum "Message Type ori") Result: JsonArray
    var
        Contracts: Codeunit "Msg Contract Mgt ori";
        Parameter: JsonObject;
    begin
        if MessageType <> MessageType::"ODBC.Source.List" then
            Result.Add(Contracts.Parameter('source', 'string', true, 'Configured source code, at most 20 characters. Use ODBC.Source.List to discover codes.'));
        if MessageType = MessageType::"ODBC.Schema.Get" then
            Result.Add(Contracts.Parameter('objectFilter', 'string', false, 'Optional catalog table/view filter, passed separately from SQL.'));
        if MessageType = MessageType::"ODBC.Query.Run" then begin
            Result.Add(Contracts.Parameter('sql', 'string', true, 'One SELECT only. No comments, statement delimiters, SELECT INTO, write, DDL or EXEC keywords. Quoted values and identifiers are supported. The driver must enforce a read-only connection.'));
            Parameter := Contracts.Parameter('parameters', 'array', false, 'Scalar values or null, in positional ? order. Placeholder count must match. Omitted means an empty array.');
            Result.Add(Parameter);
            Parameter := Contracts.Parameter('maxRows', 'integer', false, 'Positive row limit no greater than the configured source Row Cap. Omitted uses Row Cap. Applied at transport and reader.');
            Parameter.Add('minimum', 1);
            Result.Add(Parameter);
            Parameter := Contracts.Parameter('output', 'string', false, OutputParamLbl);
            Parameter.Add('enum', OutputValues());
            Parameter.Add('default', 'inline');
            Result.Add(Parameter);
        end;
    end;

    /// <summary>Declares response fields without exposing connection setup.</summary>
    procedure Response(MessageType: Enum "Message Type ori") Result: JsonObject
    var
        Contracts: Codeunit "Msg Contract Mgt ori";
        Fields: JsonArray;
        Children: JsonArray;
        ResponseField: JsonObject;
    begin
        Fields.Add(Contracts.ResponseField('status', 'string', 'Success.'));
        case MessageType of
            MessageType::"ODBC.Source.List":
                begin
                    Children.Add(Contracts.ResponseField('code', 'string', 'Source code.'));
                    Children.Add(Contracts.ResponseField('description', 'string', 'Source description.'));
                    Children.Add(Contracts.ResponseField('driverName', 'string', 'Driver from the last successful source test, or empty.'));
                    Children.Add(Contracts.ResponseField('dbmsName', 'string', 'DBMS from the last successful source test, or empty.'));
                    Children.Add(Contracts.ResponseField('readOnly', 'boolean', 'Configured source policy. Agent queries always use readOnly=true.'));
                    Children.Add(Contracts.ResponseField('blocked', 'boolean', 'Blocked sources are listed but cannot be called.'));
                    ResponseField := Contracts.ResponseField('sources', 'array', 'Configured sources only; never connection strings, DSNs, relay/blob details or keys.');
                    ResponseField.Add('children', Children);
                    Fields.Add(ResponseField);
                end;
            MessageType::"ODBC.Source.Test":
                begin
                    Fields.Add(Contracts.ResponseField('driverName', 'string', 'ODBC driver reported by the agent.'));
                    Fields.Add(Contracts.ResponseField('dbmsName', 'string', 'DBMS reported by the agent.'));
                    Fields.Add(Contracts.ResponseField('dbmsVersion', 'string', 'DBMS version reported by the agent.'));
                    Fields.Add(Contracts.ResponseField('roundTripMs', 'integer', 'Elapsed connection-test time in milliseconds.'));
                end;
            MessageType::"ODBC.Schema.Get":
                begin
                    Fields.Add(Contracts.ResponseField('dbmsName', 'string', 'DBMS dialect from the agent, falling back to the last successful source test. Test the source first if empty.'));
                    Children.Add(Contracts.ResponseField('name', 'string', 'Table or view name.'));
                    Children.Add(Contracts.ResponseField('type', 'string', 'Table or view.'));
                    ResponseField := Contracts.ResponseField('columns', 'array', 'Column objects with name (string), type (string) and nullable (boolean).');
                    Children.Add(ResponseField);
                    ResponseField := Contracts.ResponseField('objects', 'array', 'Catalog tables/views and their columns.');
                    ResponseField.Add('children', Children);
                    Fields.Add(ResponseField);
                end;
            MessageType::"ODBC.Query.Run":
                begin
                    Fields.Add(Contracts.ResponseField('staged', 'boolean', StagedFieldLbl));
                    Fields.Add(Contracts.ResponseField('stagingId', 'string', StagingIdFieldLbl));
                    Fields.Add(Contracts.ResponseField('contentType', 'string', ContentTypeFieldLbl));
                    Fields.Add(Contracts.ResponseField('byteSize', 'integer', ByteSizeFieldLbl));
                    Fields.Add(Contracts.ResponseField('columns', 'array', 'Column names in reader order, also present for an empty result.'));
                    Fields.Add(Contracts.ResponseField('rows', 'array', RowsFieldLbl));
                    Fields.Add(Contracts.ResponseField('rowCount', 'integer', 'Retained rows, no greater than maxRows or source Row Cap.'));
                    Fields.Add(Contracts.ResponseField('truncated', 'boolean', 'True when the agent or BC omitted rows.'));
                end;
        end;
        Result.Add('contentType', 'text/json');
        Result.Add('fields', Fields);
        Result.Add('whenEmpty', 'Success with an empty array and, for a query, rowCount 0.');
    end;

    /// <summary>Declares typed errors and actionable recovery.</summary>
    procedure Errors(MessageType: Enum "Message Type ori") Result: JsonArray
    var
        Contracts: Codeunit "Msg Contract Mgt ori";
    begin
        if MessageType <> MessageType::"ODBC.Source.List" then begin
            Result.Add(Contracts.ErrorEntry(Enum::"Bifrost Error Code ori"::MissingParameter, 'source is missing.', 'Send data.source from ODBC.Source.List.'));
            Result.Add(Contracts.ErrorEntry(Enum::"Bifrost Error Code ori"::InvalidParameterFormat, 'source is not text.', 'Send a source code as a JSON string.'));
            Result.Add(Contracts.ErrorEntry(Enum::"Bifrost Error Code ori"::RecordNotFound, 'The source does not exist.', 'Use ODBC.Source.List and choose an existing code.'));
        end;
        Result.Add(Contracts.ErrorEntry(Enum::"Bifrost Error Code ori"::InvalidParameter, 'A parameter, SQL statement, placeholder count or row limit is invalid.', 'Follow the parameters chapter; use one SELECT and a positive maxRows no greater than Row Cap.'));
        if MessageType = MessageType::"ODBC.Query.Run" then
            Result.Add(Contracts.ErrorEntry(Enum::"Bifrost Error Code ori"::LimitExceeded, LimitErrorWhenLbl, LimitErrorFixLbl));
        Result.Add(Contracts.ErrorEntry(Enum::"Bifrost Error Code ori"::PreconditionFailed, 'Source blocked, invalid setup, agent unavailable or malformed agent result.', 'Ask an administrator to check source setup and agent availability, then retry.'));
    end;

    /// <summary>Declares read-only source behavior and the identity cache.</summary>
    procedure Effect(MessageType: Enum "Message Type ori") Result: JsonObject
    begin
        Result.Add('effect', 'read');
        if MessageType = MessageType::"ODBC.Source.Test" then
            Result.Add('changes', 'Caches redacted driver and DBMS identity in BC. Never changes the ODBC database.')
        else
            Result.Add('changes', 'No database writes. Every transport operation uses readOnly=true.');
        Result.Add('idempotent', true);
        Result.Add('permissionSet', 'BIFROST ODBCRead ori');
    end;

    /// <summary>Provides fictitious, executable queue examples.</summary>
    procedure Examples(MessageType: Enum "Message Type ori") Result: JsonArray
    var
        Contracts: Codeunit "Msg Contract Mgt ori";
    begin
        case MessageType of
            MessageType::"ODBC.Source.List":
                Result.Add(Contracts.Example('List sources', '{"type":"ODBC.Source.List","data":{}}', '{"status":"Success","sources":[]}'));
            MessageType::"ODBC.Source.Test":
                Result.Add(Contracts.Example('Test a demo source', '{"type":"ODBC.Source.Test","data":{"source":"XDEMO"}}', '{"status":"Success","driverName":"Demo ODBC","dbmsName":"DemoDB","dbmsVersion":"1","roundTripMs":5}'));
            MessageType::"ODBC.Schema.Get":
                Result.Add(Contracts.Example('Inspect a catalog', '{"type":"ODBC.Schema.Get","data":{"source":"XDEMO","objectFilter":"Products"}}', '{"status":"Success","dbmsName":"DemoDB","objects":[]}'));
            MessageType::"ODBC.Query.Run":
                begin
                    Result.Add(Contracts.Example('Read products', '{"type":"ODBC.Query.Run","data":{"source":"XDEMO","sql":"SELECT id FROM Products WHERE id = ?","parameters":[7],"maxRows":10}}', '{"status":"Success","columns":["id"],"rows":[{"id":7}],"rowCount":1,"truncated":false,"staged":false}'));
                    Result.Add(Contracts.Example(StagedExampleLbl, '{"type":"ODBC.Query.Run","data":{"source":"XDEMO","sql":"SELECT id, name FROM Products","maxRows":5000,"output":"staged"}}', '{"status":"Success","staged":true,"stagingId":"6f1c2a7e-0b4d-4e8a-9c3f-1d2e3f4a5b6c","rowCount":5000,"columns":["id","name"],"contentType":"application/json","byteSize":181234,"truncated":false}'));
                end;
        end;
    end;

    /// <summary>Declares how a later Orchestrator playbook step uses a staged result.</summary>
    procedure Workflow() Result: JsonObject
    var
        Contracts: Codeunit "Msg Contract Mgt ori";
        Steps: JsonArray;
    begin
        Steps.Add(Contracts.WorkflowStep('ODBC.Query.Run', WorkflowQueryStepLbl));
        Steps.Add(Contracts.WorkflowStep(StagingConsumerTok, WorkflowConsumerStepLbl));
        Result.Add('steps', Steps);
        Result.Add('text', WorkflowTextLbl);
        Result.Add('example', WorkflowExampleTok);
    end;

    local procedure OutputValues() Values: JsonArray
    begin
        Values.Add('inline');
        Values.Add('staged');
    end;

    /// <summary>Returns localized queue, metering and safety guidance.</summary>
    procedure Notes(): Text
    begin
        exit(NotesLbl);
    end;

    var
        StagingConsumerTok: Label 'Storage.File.Create', Locked = true;
        WorkflowExampleTok: Label '{"steps":[{"step":10,"type":"ODBC.Query.Run","data":{"source":"XDEMO","sql":"SELECT id, name FROM Products","output":"staged"}},{"step":20,"type":"Storage.File.Create","data":{"stagingId":"@10.stagingId"}}]}', Locked = true;
        OutputParamLbl: Label 'inline (default) returns rows in the response; a result larger than the source Inline Result Limit (KB) is staged automatically. staged always stores the full result as one Blob Staging row and returns its stagingId. Nothing is truncated beyond maxRows.', Comment = 'is-IS=inline (sjálfgefið) skilar línum í svarinu; niðurstaða sem er stærri en Hámark beinnar niðurstöðu (KB) uppsprettunnar er sjálfkrafa vistuð í Blob Staging. staged vistar alltaf alla niðurstöðuna sem eina Blob Staging-línu og skilar stagingId hennar. Ekkert er stytt umfram maxRows.';
        StagedFieldLbl: Label 'True when the result was stored in Blob Staging (output staged, or inline above the source limit); then rows is absent. False for an inline result.', Comment = 'is-IS=Satt þegar niðurstaðan var vistuð í Blob Staging (output staged, eða inline yfir hámarki uppsprettu); þá vantar rows. Ósatt fyrir beina niðurstöðu.';
        StagingIdFieldLbl: Label 'Staged only. SystemId of the Blob Staging row in the current company, readable only by the user who ran the query. Pass it to a later step as stagingId, for example @10.stagingId in an Orchestrator playbook.', Comment = 'is-IS=Aðeins við vistun. SystemId Blob Staging-línunnar í núverandi fyrirtæki, aðeins læsileg þeim notanda sem keyrði fyrirspurnina. Sendu hana í síðara skref sem stagingId, t.d. @10.stagingId í Orchestrator-leikbók.';
        ContentTypeFieldLbl: Label 'Staged only. Always application/json. The staged content is {"columns":[...],"rows":[...]}, the same shape as inline output, with binary columns as base64.', Comment = 'is-IS=Aðeins við vistun. Alltaf application/json. Vistað efni er {"columns":[...],"rows":[...]}, sama lögun og bein niðurstaða, með tvíundardálka sem base64.';
        ByteSizeFieldLbl: Label 'Staged only. Size of the staged UTF-8 JSON in bytes.', Comment = 'is-IS=Aðeins við vistun. Stærð vistaðs UTF-8 JSON í bætum.';
        RowsFieldLbl: Label 'Inline only. Objects keyed by column name; scalar JSON types and null are preserved; binary columns are base64.', Comment = 'is-IS=Aðeins bein niðurstaða. Hlutir með dálkaheiti sem lykil; JSON-tegundir og null haldast; tvíundardálkar eru base64.';
        LimitErrorWhenLbl: Label 'The result is larger than the Blob Staging limit of 25 MB (26214400 bytes). The message names the size and the limit.', Comment = 'is-IS=Niðurstaðan er stærri en 25 MB (26214400 bæta) hámark Blob Staging. Skilaboðin nefna stærðina og hámarkið.';
        LimitErrorFixLbl: Label 'Lower maxRows or filter the SELECT with a WHERE clause or fewer columns, then retry.', Comment = 'is-IS=Lækkaðu maxRows eða síaðu SELECT-setninguna með WHERE-skilyrði eða færri dálkum og reyndu aftur.';
        StagedExampleLbl: Label 'Stage a large result', Comment = 'is-IS=Vista stóra niðurstöðu';
        WorkflowQueryStepLbl: Label 'Step 10: run the query with output staged. The response holds the stagingId.', Comment = 'is-IS=Skref 10: keyrðu fyrirspurnina með output staged. Svarið inniheldur stagingId.';
        WorkflowConsumerStepLbl: Label 'Step 20: pass "stagingId": "@10.stagingId" to any type that takes a stagingId, for example to store the result as a file.', Comment = 'is-IS=Skref 20: sendu "stagingId": "@10.stagingId" í hvaða tegund sem tekur stagingId, t.d. til að vista niðurstöðuna sem skrá.';
        WorkflowTextLbl: Label 'Orchestrator playbooks run every step as the same user and company, so a later step can read the staged row without extra code. The row is used up when a consumer takes it; unused rows are removed by the Foundation Blob Staging retention policy.', Comment = 'is-IS=Orchestrator-leikbækur keyra hvert skref sem sami notandi og fyrirtæki, svo síðara skref getur lesið vistuðu línuna án aukakóða. Línan er notuð upp þegar viðtakandi tekur hana; ónotaðar línur eru fjarlægðar af varðveislustefnu Blob Staging í Foundation.';
        NotesLbl: Label 'Submit to POST /queues. Foundation meters every call. ODBC sources are read-only for agents, including sources that allow AL writes. Use positional ? parameters; never concatenate values into SQL. Responses redact stored connection secrets. Source.Test caches public identity. Licence-path checks are performed before release.', Comment = 'is-IS=Sendu á POST /queues. Foundation mælir hvert kall. ODBC-uppsprettur eru eingöngu til lestrar fyrir miðlara, einnig þær sem leyfa AL-skrif. Notaðu stika í röð með ?; aldrei skeyta gildum inn í SQL. Svör fela geymd tengileyndarmál. Source.Test vistar opinbert auðkenni. Leyfisleiðir eru prófaðar fyrir útgáfu.';
}
