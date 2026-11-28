namespace Origo.Bifrost.ODBC.Test;

using Microsoft.Foundation.Company;
using Origo.Bifrost;
using Origo.Bifrost.ODBC;
using System.Globalization;
using System.TestLibraries.Utilities;
using System.Utilities;

/// <summary>Story #3: public dispatch, contracts, pre-transport refusals and secret protection in both locales.</summary>
codeunit 98140 "ODBC Messages Tst ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Mock: Codeunit "ODBC Mock Transport ori";
        OriginalLanguage: Integer;
        OriginalDefaultLanguage: Text;
        LanguageId: Integer;
        FakeConnectionLbl: Label 'Driver={Mock};Server=example.invalid;Password=x-unit-only;', Locked = true;
        FakeKeyLbl: Label 'MDEyMzQ1Njc4OWFiY2RlZg==', Locked = true;
        BinaryResultLbl: Label '{"columns":["id","name","picture"],"rows":[{"id":1,"name":"Bicycle","picture":"AAECAwT/"},{"id":2,"name":"Tent","picture":null}]}', Locked = true;

    /// <summary>Story #18 StagedOutput in LCID 1033.</summary>
    [Test]
    procedure StagedOutput_1033()
    begin
        Initialize(1033);
        VerifyStagedOutput();
        Cleanup();
    end;

    /// <summary>Story #18 InlineOutput in LCID 1033.</summary>
    [Test]
    procedure InlineOutput_1033()
    begin
        Initialize(1033);
        VerifyInlineOutput();
        Cleanup();
    end;

    /// <summary>Story #18 AutoStage in LCID 1033.</summary>
    [Test]
    procedure AutoStage_1033()
    begin
        Initialize(1033);
        VerifyAutoStage();
        Cleanup();
    end;

    /// <summary>Story #18 StagedSizeCap in LCID 1033.</summary>
    [Test]
    procedure StagedSizeCap_1033()
    begin
        Initialize(1033);
        VerifyStagedSizeCap();
        Cleanup();
    end;

    /// <summary>Story #18 InvalidOutput in LCID 1033.</summary>
    [Test]
    procedure InvalidOutput_1033()
    begin
        Initialize(1033);
        VerifyInvalidOutput();
        Cleanup();
    end;

    /// <summary>Story #18 StagingIdIsolation in LCID 1033.</summary>
    [Test]
    procedure StagingIdIsolation_1033()
    begin
        Initialize(1033);
        VerifyStagingIdIsolation();
        Cleanup();
    end;

    /// <summary>Story #18 StagedOutput in LCID 1039.</summary>
    [Test]
    procedure StagedOutput_1039()
    begin
        Initialize(1039);
        VerifyStagedOutput();
        Cleanup();
    end;

    /// <summary>Story #18 InlineOutput in LCID 1039.</summary>
    [Test]
    procedure InlineOutput_1039()
    begin
        Initialize(1039);
        VerifyInlineOutput();
        Cleanup();
    end;

    /// <summary>Story #18 AutoStage in LCID 1039.</summary>
    [Test]
    procedure AutoStage_1039()
    begin
        Initialize(1039);
        VerifyAutoStage();
        Cleanup();
    end;

    /// <summary>Story #18 StagedSizeCap in LCID 1039.</summary>
    [Test]
    procedure StagedSizeCap_1039()
    begin
        Initialize(1039);
        VerifyStagedSizeCap();
        Cleanup();
    end;

    /// <summary>Story #18 InvalidOutput in LCID 1039.</summary>
    [Test]
    procedure InvalidOutput_1039()
    begin
        Initialize(1039);
        VerifyInvalidOutput();
        Cleanup();
    end;

    /// <summary>Story #18 StagingIdIsolation in LCID 1039.</summary>
    [Test]
    procedure StagingIdIsolation_1039()
    begin
        Initialize(1039);
        VerifyStagingIdIsolation();
        Cleanup();
    end;

    /// <summary>Contracts in LCID 1033.</summary>
    [Test]
    procedure Contracts_1033()
    begin
        Initialize(1033);
        VerifyContracts();
        Cleanup();
    end;

    /// <summary>SourceList in LCID 1033.</summary>
    [Test]
    procedure SourceList_1033()
    begin
        Initialize(1033);
        VerifySourceList();
        Cleanup();
    end;

    /// <summary>SourceTest in LCID 1033.</summary>
    [Test]
    procedure SourceTest_1033()
    begin
        Initialize(1033);
        VerifySourceTest();
        Cleanup();
    end;

    /// <summary>Schema in LCID 1033.</summary>
    [Test]
    procedure Schema_1033()
    begin
        Initialize(1033);
        VerifySchema();
        Cleanup();
    end;

    /// <summary>Query in LCID 1033.</summary>
    [Test]
    procedure Query_1033()
    begin
        Initialize(1033);
        VerifyQuery();
        Cleanup();
    end;

    /// <summary>EmptyRows in LCID 1033.</summary>
    [Test]
    procedure EmptyRows_1033()
    begin
        Initialize(1033);
        VerifyEmptyRows();
        Cleanup();
    end;

    /// <summary>RowCap in LCID 1033.</summary>
    [Test]
    procedure RowCap_1033()
    begin
        Initialize(1033);
        VerifyRowCap();
        Cleanup();
    end;

    /// <summary>UnknownBlocked in LCID 1033.</summary>
    [Test]
    procedure UnknownBlocked_1033()
    begin
        Initialize(1033);
        VerifyUnknownBlocked();
        Cleanup();
    end;

    /// <summary>InvalidInput in LCID 1033.</summary>
    [Test]
    procedure InvalidInput_1033()
    begin
        Initialize(1033);
        VerifyInvalidInput();
        Cleanup();
    end;

    /// <summary>SecretResponses in LCID 1033.</summary>
    [Test]
    procedure SecretResponses_1033()
    begin
        Initialize(1033);
        VerifySecretResponses();
        Cleanup();
    end;

    /// <summary>SecretErrors in LCID 1033.</summary>
    [Test]
    procedure SecretErrors_1033()
    begin
        Initialize(1033);
        VerifySecretErrors();
        Cleanup();
    end;

    /// <summary>QuotedSql in LCID 1033.</summary>
    [Test]
    procedure QuotedSql_1033()
    begin
        Initialize(1033);
        VerifyQuotedSql();
        Cleanup();
    end;

    /// <summary>Refuses Insert before transport in LCID 1033.</summary>
    [Test]
    procedure RefuseInsert_1033()
    begin
        Initialize(1033);
        AssertRefused('INSERT INTO demo VALUES (1)');
        Cleanup();
    end;

    /// <summary>Refuses Update before transport in LCID 1033.</summary>
    [Test]
    procedure RefuseUpdate_1033()
    begin
        Initialize(1033);
        AssertRefused('UPDATE demo SET id=1');
        Cleanup();
    end;

    /// <summary>Refuses Delete before transport in LCID 1033.</summary>
    [Test]
    procedure RefuseDelete_1033()
    begin
        Initialize(1033);
        AssertRefused('DELETE FROM demo');
        Cleanup();
    end;

    /// <summary>Refuses Merge before transport in LCID 1033.</summary>
    [Test]
    procedure RefuseMerge_1033()
    begin
        Initialize(1033);
        AssertRefused('MERGE INTO demo USING demo2 ON 1=1 WHEN MATCHED THEN DELETE');
        Cleanup();
    end;

    /// <summary>Refuses DDL before transport in LCID 1033.</summary>
    [Test]
    procedure RefuseDDL_1033()
    begin
        Initialize(1033);
        AssertRefused('CREATE TABLE demo (id int)');
        Cleanup();
    end;

    /// <summary>Refuses Alter before transport in LCID 1033.</summary>
    [Test]
    procedure RefuseAlter_1033()
    begin
        Initialize(1033);
        AssertRefused('ALTER TABLE demo ADD id int');
        Cleanup();
    end;

    /// <summary>Refuses Drop before transport in LCID 1033.</summary>
    [Test]
    procedure RefuseDrop_1033()
    begin
        Initialize(1033);
        AssertRefused('DROP TABLE demo');
        Cleanup();
    end;

    /// <summary>Refuses Exec before transport in LCID 1033.</summary>
    [Test]
    procedure RefuseExec_1033()
    begin
        Initialize(1033);
        AssertRefused('EXEC demo');
        Cleanup();
    end;

    /// <summary>Refuses Multiple before transport in LCID 1033.</summary>
    [Test]
    procedure RefuseMultiple_1033()
    begin
        Initialize(1033);
        AssertRefused('SELECT 1; SELECT 2');
        Cleanup();
    end;

    /// <summary>Refuses SelectInto before transport in LCID 1033.</summary>
    [Test]
    procedure RefuseSelectInto_1033()
    begin
        Initialize(1033);
        AssertRefused('SELECT id INTO demo2 FROM demo');
        Cleanup();
    end;

    /// <summary>Refuses EmbeddedWrite before transport in LCID 1033.</summary>
    [Test]
    procedure RefuseEmbeddedWrite_1033()
    begin
        Initialize(1033);
        AssertRefused('SELECT 1 UNION DELETE FROM demo');
        Cleanup();
    end;

    /// <summary>Refuses Comments before transport in LCID 1033.</summary>
    [Test]
    procedure RefuseComments_1033()
    begin
        Initialize(1033);
        AssertRefused('SELECT 1 /* comment */');
        Cleanup();
    end;

    /// <summary>Refuses CommentPrefix before transport in LCID 1033.</summary>
    [Test]
    procedure RefuseCommentPrefix_1033()
    begin
        Initialize(1033);
        AssertRefused('-- comment SELECT 1');
        Cleanup();
    end;

    /// <summary>Refuses UnclosedQuote before transport in LCID 1033.</summary>
    [Test]
    procedure RefuseUnclosedQuote_1033()
    begin
        Initialize(1033);
        AssertRefused('SELECT ''open');
        Cleanup();
    end;

    /// <summary>Refuses OutputFile before transport in LCID 1033.</summary>
    [Test]
    procedure RefuseOutputFile_1033()
    begin
        Initialize(1033);
        AssertRefused('SELECT 1 INTO OUTFILE ''demo''');
        Cleanup();
    end;

    /// <summary>Refuses ParameterMismatch before transport in LCID 1033.</summary>
    [Test]
    procedure RefuseParameterMismatch_1033()
    begin
        Initialize(1033);
        AssertRefused('SELECT ?');
        Cleanup();
    end;

    /// <summary>Contracts in LCID 1039.</summary>
    [Test]
    procedure Contracts_1039()
    begin
        Initialize(1039);
        VerifyContracts();
        Cleanup();
    end;

    /// <summary>SourceList in LCID 1039.</summary>
    [Test]
    procedure SourceList_1039()
    begin
        Initialize(1039);
        VerifySourceList();
        Cleanup();
    end;

    /// <summary>SourceTest in LCID 1039.</summary>
    [Test]
    procedure SourceTest_1039()
    begin
        Initialize(1039);
        VerifySourceTest();
        Cleanup();
    end;

    /// <summary>Schema in LCID 1039.</summary>
    [Test]
    procedure Schema_1039()
    begin
        Initialize(1039);
        VerifySchema();
        Cleanup();
    end;

    /// <summary>Query in LCID 1039.</summary>
    [Test]
    procedure Query_1039()
    begin
        Initialize(1039);
        VerifyQuery();
        Cleanup();
    end;

    /// <summary>EmptyRows in LCID 1039.</summary>
    [Test]
    procedure EmptyRows_1039()
    begin
        Initialize(1039);
        VerifyEmptyRows();
        Cleanup();
    end;

    /// <summary>RowCap in LCID 1039.</summary>
    [Test]
    procedure RowCap_1039()
    begin
        Initialize(1039);
        VerifyRowCap();
        Cleanup();
    end;

    /// <summary>UnknownBlocked in LCID 1039.</summary>
    [Test]
    procedure UnknownBlocked_1039()
    begin
        Initialize(1039);
        VerifyUnknownBlocked();
        Cleanup();
    end;

    /// <summary>InvalidInput in LCID 1039.</summary>
    [Test]
    procedure InvalidInput_1039()
    begin
        Initialize(1039);
        VerifyInvalidInput();
        Cleanup();
    end;

    /// <summary>SecretResponses in LCID 1039.</summary>
    [Test]
    procedure SecretResponses_1039()
    begin
        Initialize(1039);
        VerifySecretResponses();
        Cleanup();
    end;

    /// <summary>SecretErrors in LCID 1039.</summary>
    [Test]
    procedure SecretErrors_1039()
    begin
        Initialize(1039);
        VerifySecretErrors();
        Cleanup();
    end;

    /// <summary>QuotedSql in LCID 1039.</summary>
    [Test]
    procedure QuotedSql_1039()
    begin
        Initialize(1039);
        VerifyQuotedSql();
        Cleanup();
    end;

    /// <summary>Refuses Insert before transport in LCID 1039.</summary>
    [Test]
    procedure RefuseInsert_1039()
    begin
        Initialize(1039);
        AssertRefused('INSERT INTO demo VALUES (1)');
        Cleanup();
    end;

    /// <summary>Refuses Update before transport in LCID 1039.</summary>
    [Test]
    procedure RefuseUpdate_1039()
    begin
        Initialize(1039);
        AssertRefused('UPDATE demo SET id=1');
        Cleanup();
    end;

    /// <summary>Refuses Delete before transport in LCID 1039.</summary>
    [Test]
    procedure RefuseDelete_1039()
    begin
        Initialize(1039);
        AssertRefused('DELETE FROM demo');
        Cleanup();
    end;

    /// <summary>Refuses Merge before transport in LCID 1039.</summary>
    [Test]
    procedure RefuseMerge_1039()
    begin
        Initialize(1039);
        AssertRefused('MERGE INTO demo USING demo2 ON 1=1 WHEN MATCHED THEN DELETE');
        Cleanup();
    end;

    /// <summary>Refuses DDL before transport in LCID 1039.</summary>
    [Test]
    procedure RefuseDDL_1039()
    begin
        Initialize(1039);
        AssertRefused('CREATE TABLE demo (id int)');
        Cleanup();
    end;

    /// <summary>Refuses Alter before transport in LCID 1039.</summary>
    [Test]
    procedure RefuseAlter_1039()
    begin
        Initialize(1039);
        AssertRefused('ALTER TABLE demo ADD id int');
        Cleanup();
    end;

    /// <summary>Refuses Drop before transport in LCID 1039.</summary>
    [Test]
    procedure RefuseDrop_1039()
    begin
        Initialize(1039);
        AssertRefused('DROP TABLE demo');
        Cleanup();
    end;

    /// <summary>Refuses Exec before transport in LCID 1039.</summary>
    [Test]
    procedure RefuseExec_1039()
    begin
        Initialize(1039);
        AssertRefused('EXEC demo');
        Cleanup();
    end;

    /// <summary>Refuses Multiple before transport in LCID 1039.</summary>
    [Test]
    procedure RefuseMultiple_1039()
    begin
        Initialize(1039);
        AssertRefused('SELECT 1; SELECT 2');
        Cleanup();
    end;

    /// <summary>Refuses SelectInto before transport in LCID 1039.</summary>
    [Test]
    procedure RefuseSelectInto_1039()
    begin
        Initialize(1039);
        AssertRefused('SELECT id INTO demo2 FROM demo');
        Cleanup();
    end;

    /// <summary>Refuses EmbeddedWrite before transport in LCID 1039.</summary>
    [Test]
    procedure RefuseEmbeddedWrite_1039()
    begin
        Initialize(1039);
        AssertRefused('SELECT 1 UNION DELETE FROM demo');
        Cleanup();
    end;

    /// <summary>Refuses Comments before transport in LCID 1039.</summary>
    [Test]
    procedure RefuseComments_1039()
    begin
        Initialize(1039);
        AssertRefused('SELECT 1 /* comment */');
        Cleanup();
    end;

    /// <summary>Refuses CommentPrefix before transport in LCID 1039.</summary>
    [Test]
    procedure RefuseCommentPrefix_1039()
    begin
        Initialize(1039);
        AssertRefused('-- comment SELECT 1');
        Cleanup();
    end;

    /// <summary>Refuses UnclosedQuote before transport in LCID 1039.</summary>
    [Test]
    procedure RefuseUnclosedQuote_1039()
    begin
        Initialize(1039);
        AssertRefused('SELECT ''open');
        Cleanup();
    end;

    /// <summary>Refuses OutputFile before transport in LCID 1039.</summary>
    [Test]
    procedure RefuseOutputFile_1039()
    begin
        Initialize(1039);
        AssertRefused('SELECT 1 INTO OUTFILE ''demo''');
        Cleanup();
    end;

    /// <summary>Refuses ParameterMismatch before transport in LCID 1039.</summary>
    [Test]
    procedure RefuseParameterMismatch_1039()
    begin
        Initialize(1039);
        AssertRefused('SELECT ?');
        Cleanup();
    end;

    /// <summary>Refuses a second top-level SELECT even without a statement delimiter, LCID 1033.</summary>
    [Test]
    procedure RefuseSecondSelect_1033()
    begin
        Initialize(1033);
        AssertRefused('SELECT 1 SELECT 2');
        Cleanup();
    end;

    /// <summary>Refuses a second top-level SELECT even without a statement delimiter, LCID 1039.</summary>
    [Test]
    procedure RefuseSecondSelect_1039()
    begin
        Initialize(1039);
        AssertRefused('SELECT 1 SELECT 2');
        Cleanup();
    end;

    /// <summary>Refuses ambiguous DollarQuotes dialect quoting before transport, LCID 1033.</summary>
    [Test]
    procedure RefuseDollarQuotes_1033()
    begin
        Initialize(1033);
        AssertRefused('SELECT $$''$$;DELETE FROM demo;--''');
        Cleanup();
    end;

    /// <summary>Refuses ambiguous BackslashQuotes dialect quoting before transport, LCID 1033.</summary>
    [Test]
    procedure RefuseBackslashQuotes_1033()
    begin
        Initialize(1033);
        AssertRefused('SELECT ''\'' '';DELETE FROM demo;--''');
        Cleanup();
    end;

    /// <summary>Refuses ambiguous DollarQuotes dialect quoting before transport, LCID 1039.</summary>
    [Test]
    procedure RefuseDollarQuotes_1039()
    begin
        Initialize(1039);
        AssertRefused('SELECT $$''$$;DELETE FROM demo;--''');
        Cleanup();
    end;

    /// <summary>Refuses ambiguous BackslashQuotes dialect quoting before transport, LCID 1039.</summary>
    [Test]
    procedure RefuseBackslashQuotes_1039()
    begin
        Initialize(1039);
        AssertRefused('SELECT ''\'' '';DELETE FROM demo;--''');
        Cleanup();
    end;

    /// <summary>Ordinary scalar text survives secret filtering in LCID 1033.</summary>
    [Test]
    procedure ResultValues_1033()
    begin
        Initialize(1033);
        VerifyResultValues();
        Cleanup();
    end;

    /// <summary>Ordinary scalar text survives secret filtering in LCID 1039.</summary>
    [Test]
    procedure ResultValues_1039()
    begin
        Initialize(1039);
        VerifyResultValues();
        Cleanup();
    end;

    local procedure VerifyResultValues()
    var
        Source: Record "ODBC Source ori";
        Relay: Record "ODBC Relay Connection ori";
        Secrets: Codeunit "ODBC Secret Mgt ori";
        LongSecret: SecretText;
        Reply: JsonObject;
        Payload: JsonObject;
        Row: JsonObject;
        Rows: JsonArray;
        Item: JsonToken;
        Body: Text;
        LongText: Text;
    begin
        // [GIVEN] Configured fake secrets and ordinary URL, key=value and >256-character data.
        // Messages use public dispatch; there is no corresponding UI action.
        LongText := PadStr('description=', 257, 'x');
        Row.Add('url', 'https://public.invalid/docs');
        Row.Add('key=value', 'key=value');
        Row.Add('long', LongText);
        Row.Add('embedded', LongText + 'fake-relay-key' + ' tail');
        Row.Add('adjacent', 'fake-relay-key' + 'fake-relay-key');
        Row.Add('number', 7);
        Row.Add('boolean', true);
        Row.Add('empty', '');
        Rows.Add(Row);
        Payload.Add('rows', Rows);
        Payload.WriteTo(Body);
        Mock.SetResponse(Body);

        // [WHEN] Query and schema results pass through the message handler.
        Reply := Invoke(Enum::"Message Type ori"::"ODBC.Query.Run", '{"source":"XODBCMSG","sql":"SELECT id FROM demo"}');
        AssertSuccess(Reply);
        Reply.GetArray('rows').Get(0, Item);
        AssertResultValues(Item.AsObject(), LongText);
        Clear(Payload);
        Payload.Add('objects', Rows);
        Payload.Add('dbmsName', 'dbms=value');
        Payload.WriteTo(Body);
        Mock.SetResponse(Body);
        Reply := Invoke(Enum::"Message Type ori"::"ODBC.Schema.Get", '{"source":"XODBCMSG"}');
        AssertSuccess(Reply);
        Reply.GetArray('objects').Get(0, Item);
        AssertResultValues(Item.AsObject(), LongText);
        Assert.AreEqual('dbms=value', Reply.GetText('dbmsName'), 'Schema identity preserved');

        // [THEN] Source identity and descriptions also preserve ordinary URL/key=value data.
        Mock.SetResponse('{"driverName":"driver=value","dbmsName":"https://public.invalid/db","dbmsVersion":"version=1"}');
        Reply := Invoke(Enum::"Message Type ori"::"ODBC.Source.Test", '{"source":"XODBCMSG"}');
        AssertSuccess(Reply);
        Assert.AreEqual('driver=value', Reply.GetText('driverName'), 'Driver identity preserved');
        Assert.AreEqual('https://public.invalid/db', Reply.GetText('dbmsName'), 'DBMS URL preserved');
        Assert.AreEqual('version=1', Reply.GetText('dbmsVersion'), 'Version preserved');
        Source.Get('XODBCMSG');
        Source.Description := 'https://public.invalid/docs?key=value';
        Source.Modify();
        Reply := Invoke(Enum::"Message Type ori"::"ODBC.Source.List", '{}');
        AssertSuccess(Reply);
        foreach Item in Reply.GetArray('sources') do
            if Item.AsObject().GetText('code') = Source.Code then begin
                Assert.AreEqual(Source.Description, Item.AsObject().GetText('description'), 'Source description preserved');
                Assert.AreEqual('driver=value', Item.AsObject().GetText('driverName'), 'Cached driver preserved');
                Assert.AreEqual('https://public.invalid/db', Item.AsObject().GetText('dbmsName'), 'Cached DBMS preserved');
            end;
        // [GIVEN] An embedded stored secret that is itself longer than the diagnostic bound.
        Relay.Get(Source."Relay Connection Code");
        LongSecret := LongText;
        Secrets.SetSecret(Relay.SystemId, Enum::"ODBC Secret Kind ori"::RelaySasKey, LongSecret);
        Clear(Payload);
        Clear(Row);
        Clear(Rows);
        Row.Add('longSecret', 'prefix ' + LongText + ' suffix');
        Rows.Add(Row);
        Payload.Add('rows', Rows);
        Payload.WriteTo(Body);
        Mock.SetResponse(Body);
        Reply := Invoke(Enum::"Message Type ori"::"ODBC.Query.Run", '{"source":"XODBCMSG","sql":"SELECT id FROM demo"}');
        AssertSuccess(Reply);
        Reply.GetArray('rows').Get(0, Item);
        Assert.AreEqual('prefix [redacted] suffix', Item.AsObject().GetText('longSecret'), 'Embedded secrets longer than 256 characters are removed');
    end;

    local procedure AssertResultValues(Row: JsonObject; LongText: Text)
    begin
        Assert.AreEqual('https://public.invalid/docs', Row.GetText('url'), 'URL preserved');
        Assert.AreEqual('key=value', Row.GetText('key=value'), 'Property name and value preserved');
        Assert.AreEqual(LongText, Row.GetText('long'), '257-character scalar preserved');
        Assert.AreEqual(LongText + '[redacted] tail', Row.GetText('embedded'), 'Secret after diagnostic boundary removed without losing ordinary text');
        Assert.AreEqual('[redacted][redacted]', Row.GetText('adjacent'), 'Repeated adjacent secrets removed');
        Assert.AreEqual(7, Row.GetInteger('number'), 'Numeric type preserved');
        Assert.IsTrue(Row.GetBoolean('boolean'), 'Boolean type preserved');
        Assert.AreEqual('', Row.GetText('empty'), 'Empty text preserved');
    end;

    /// <summary>Data values with URLs, key=value text and long text are returned unchanged in LCID 1033.</summary>
    [Test]
    procedure DataPreserved_1033()
    begin
        Initialize(1033);
        VerifyDataPreserved();
        Cleanup();
    end;

    /// <summary>The Read role caches the Source.Test identity through the handler but cannot edit the source in LCID 1033.</summary>
    [Test]
    procedure ReadRoleSourceTest_1033()
    begin
        Initialize(1033);
        VerifyReadRoleSourceTest();
        Cleanup();
    end;

    /// <summary>Data values with URLs, key=value text and long text are returned unchanged in LCID 1039.</summary>
    [Test]
    procedure DataPreserved_1039()
    begin
        Initialize(1039);
        VerifyDataPreserved();
        Cleanup();
    end;

    /// <summary>The Read role caches the Source.Test identity through the handler but cannot edit the source in LCID 1039.</summary>
    [Test]
    procedure ReadRoleSourceTest_1039()
    begin
        Initialize(1039);
        VerifyReadRoleSourceTest();
        Cleanup();
    end;

    local procedure VerifyDataPreserved()
    var
        Reply: JsonObject;
        Row: JsonObject;
        LongText: Text;
        Index: Integer;
    begin
        for Index := 1 to 30 do
            LongText += 'Long text ' + Format(Index mod 10);
        Mock.SetResponse('{"driverName":"Driver=Mock","dbmsName":"MockDB=1","dbmsVersion":"https://example.org/v1"}');
        Reply := Invoke(Enum::"Message Type ori"::"ODBC.Source.Test", '{"source":"XODBCMSG"}');
        AssertSuccess(Reply);
        Assert.AreEqual('Driver=Mock', Reply.GetText('driverName'), 'Driver identity with = preserved');
        Assert.AreEqual('https://example.org/v1', Reply.GetText('dbmsVersion'), 'Version URL preserved');
        Mock.SetResponse('{"dbmsName":"MockDB","objects":[{"name":"demo","type":"TABLE","remarks":"key=value https://example.org/doc"}]}');
        Reply := Invoke(Enum::"Message Type ori"::"ODBC.Schema.Get", '{"source":"XODBCMSG"}');
        AssertSuccess(Reply);
        Assert.AreEqual('key=value https://example.org/doc', Reply.GetArray('objects').GetObject(0).GetText('remarks'), 'Catalogue text preserved');
        Mock.SetResponse('{"columns":["url","pair","long","mixed"],"rows":[{"url":"https://example.org/a?b=c","pair":"key=value","long":"' + LongText + '","mixed":"before fake-relay-key after=1"}]}');
        Reply := Invoke(Enum::"Message Type ori"::"ODBC.Query.Run", '{"source":"XODBCMSG","sql":"SELECT url, pair, long, mixed FROM demo","maxRows":1}');
        AssertSuccess(Reply);
        Row := Reply.GetArray('rows').GetObject(0);
        Assert.AreEqual('https://example.org/a?b=c', Row.GetText('url'), 'URL cell preserved');
        Assert.AreEqual('key=value', Row.GetText('pair'), 'key=value cell preserved');
        Assert.IsTrue(StrLen(LongText) > 256, 'Long fixture exceeds the diagnostic bound');
        Assert.AreEqual(LongText, Row.GetText('long'), 'Long cell preserved');
        Assert.AreEqual('before [redacted] after=1', Row.GetText('mixed'), 'Only the embedded secret is redacted');
    end;

    local procedure VerifyReadRoleSourceTest()
    var
        Source: Record "ODBC Source ori";
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "ODBC Message Handler ori";
        LowerPermissions: Codeunit "Library - Lower Permissions";
        Request: JsonObject;
        CanEdit: Boolean;
    begin
        Mock.SetResponse('{"driverName":"Read Role Driver","dbmsName":"ReadRoleDB","dbmsVersion":"1.0"}');
        Request.Add('source', 'XODBCMSG');
        TempArgument.Init();
        TempArgument.Insert();
        TempArgument.SetRequestJson(Request);
        LowerPermissions.SetExactPermissionSet('BIFROST ODBCRead ori');
        CanEdit := Source.WritePermission();
        Handler.Execute(Enum::"Message Type ori"::"ODBC.Source.Test", TempArgument);
        LowerPermissions.SetOutsideO365Scope();
        Assert.IsFalse(CanEdit, 'The Read role must not have write permission on sources.');
        Source.Get('XODBCMSG');
        Assert.AreEqual('ReadRoleDB', Source."DBMS Name", 'Handler caches the identity under the Read role');
        Assert.AreEqual('Read Role Driver', Source."Driver Name", 'Handler caches the driver under the Read role');
        // Last step: asserterror rolls back the uncommitted fixture together with the refused edit.
        LowerPermissions.SetExactPermissionSet('BIFROST ODBCRead ori');
        Source."Read Only" := false;
        asserterror Source.Modify();
        LowerPermissions.SetOutsideO365Scope();
    end;

    local procedure VerifyStagedOutput()
    var
        Inline: JsonObject;
        Staged: JsonObject;
        Expected: JsonObject;
        ExpectedText: Text;
        StagedText: Text;
        ContentType: Text;
        FileName: Text;
        ByteSize: BigInteger;
    begin
        // [GIVEN] A result with a binary column (base64 from the agent) on the mock transport.
        Mock.SetResponse(BinaryResultLbl);
        // [WHEN] The same query runs inline and staged.
        Inline := Invoke(Enum::"Message Type ori"::"ODBC.Query.Run", '{"source":"XODBCMSG","sql":"SELECT id, name, picture FROM demo"}');
        AssertSuccess(Inline);
        Mock.SetResponse(BinaryResultLbl);
        Staged := Invoke(Enum::"Message Type ori"::"ODBC.Query.Run", '{"source":"XODBCMSG","sql":"SELECT id, name, picture FROM demo","output":"staged"}');
        AssertSuccess(Staged);
        // [THEN] The staged response carries the reference and metadata but no rows.
        Assert.IsTrue(Staged.GetBoolean('staged'), 'Staged flag');
        Assert.IsFalse(Staged.Contains('rows'), 'No rows in a staged response');
        Assert.AreEqual(2, Staged.GetInteger('rowCount'), 'Staged row count');
        Assert.AreEqual(3, Staged.GetArray('columns').Count(), 'Staged columns');
        Assert.AreEqual('application/json', Staged.GetText('contentType'), 'Staged content type');
        // [THEN] The staging row holds exactly the inline JSON shape, binary column as base64.
        ByteSize := TakeStaged(Staged, StagedText, ContentType, FileName);
        Assert.AreEqual(Staged.GetBigInteger('byteSize'), ByteSize, 'byteSize matches the staged bytes');
        Assert.AreEqual('application/json', ContentType, 'Stored content type');
        Assert.IsTrue(FileName.StartsWith('XODBCMSG-') and FileName.EndsWith('.json') and (StrLen(FileName) = StrLen('XODBCMSG-yyyyMMddHHmmss.json')), 'File name pattern: ' + FileName);
        Expected.Add('columns', Inline.GetArray('columns'));
        Expected.Add('rows', Inline.GetArray('rows'));
        Expected.WriteTo(ExpectedText);
        Assert.AreEqual(ExpectedText, StagedText, 'Staged content equals inline output');
        Assert.AreEqual('AAECAwT/', Inline.GetArray('rows').GetObject(0).GetText('picture'), 'Binary stays base64 inline');
        Assert.IsTrue(StagedText.Contains('"picture":"AAECAwT/"'), 'Binary stays base64 staged');
    end;

    local procedure VerifyInlineOutput()
    var
        Reply: JsonObject;
    begin
        // [GIVEN] A small result under the default 1 MB inline limit.
        Mock.SetResponse(BinaryResultLbl);
        // [WHEN] output is inline explicitly and by default.
        Reply := Invoke(Enum::"Message Type ori"::"ODBC.Query.Run", '{"source":"XODBCMSG","sql":"SELECT id FROM demo","output":"inline"}');
        // [THEN] The response is unchanged: rows present, no staging reference.
        AssertSuccess(Reply);
        Assert.IsFalse(Reply.GetBoolean('staged'), 'Not staged');
        Assert.IsFalse(Reply.Contains('stagingId'), 'No stagingId inline');
        Assert.AreEqual(2, Reply.GetArray('rows').Count(), 'Rows present');
        Mock.SetResponse(BinaryResultLbl);
        Reply := Invoke(Enum::"Message Type ori"::"ODBC.Query.Run", '{"source":"XODBCMSG","sql":"SELECT id FROM demo"}');
        AssertSuccess(Reply);
        Assert.IsFalse(Reply.GetBoolean('staged'), 'Default output is inline');
        Assert.AreEqual(2, Reply.GetInteger('rowCount'), 'Inline row count');
    end;

    local procedure VerifyAutoStage()
    var
        Source: Record "ODBC Source ori";
        Reply: JsonObject;
        Body: Text;
        StagedText: Text;
        ContentType: Text;
        FileName: Text;
    begin
        // [GIVEN] A source with a 1 KB inline limit and a result of 100 short rows, about 2 KB.
        // Short cell values keep the per-value secret scan (RedactValue, quadratic in the value length) fast.
        Source.Get('XODBCMSG');
        Assert.AreEqual(1024, Source."Inline Result Limit (KB)", 'Default inline limit is 1 MB');
        Source."Inline Result Limit (KB)" := 1;
        Source."Row Cap" := 500;
        Source.Modify();
        Body := ShortRowsResult(100);
        Mock.SetResponse(Body);
        // [WHEN] The query runs with the default inline output.
        Reply := Invoke(Enum::"Message Type ori"::"ODBC.Query.Run", '{"source":"XODBCMSG","sql":"SELECT short FROM demo"}');
        // [THEN] It is staged automatically and nothing is truncated.
        AssertSuccess(Reply);
        Assert.IsTrue(Reply.GetBoolean('staged'), 'Auto-staged above the inline limit');
        Assert.IsFalse(Reply.Contains('rows'), 'No rows when auto-staged');
        Assert.IsFalse(Reply.GetBoolean('truncated'), 'Nothing truncated');
        Assert.AreEqual(100, Reply.GetInteger('rowCount'), 'All rows staged');
        TakeStaged(Reply, StagedText, ContentType, FileName);
        Assert.AreEqual(100, (StrLen(StagedText) - StrLen(StagedText.Replace('"short":"yyyyyyyyyy"', ''))) div StrLen('"short":"yyyyyyyyyy"'), 'All 100 full values staged');
    end;

    local procedure VerifyStagedSizeCap()
    var
        Source: Record "ODBC Source ori";
        CapStub: Codeunit "ODBC Staging Cap Stub ori";
        Reply: JsonObject;
        Inline: JsonObject;
        Expected: JsonObject;
        Body: Text;
        ExpectedText: Text;
    begin
        // [GIVEN] The staging cap lowered to 1024 bytes through the internal test seam (production cap: 25 MB, 26214400 bytes)
        // and a result of 100 short rows, about 2 KB.
        Source.Get('XODBCMSG');
        Source."Row Cap" := 500;
        Source.Modify();
        Body := ShortRowsResult(100);
        // The expected size is the staged JSON shape of the same result, read inline first.
        Mock.SetResponse(Body);
        Inline := Invoke(Enum::"Message Type ori"::"ODBC.Query.Run", '{"source":"XODBCMSG","sql":"SELECT short FROM demo"}');
        AssertSuccess(Inline);
        Expected.Add('columns', Inline.GetArray('columns'));
        Expected.Add('rows', Inline.GetArray('rows'));
        Expected.WriteTo(ExpectedText);
        BindSubscription(CapStub);
        Mock.SetResponse(Body);
        // [WHEN] The query asks for staged output.
        Reply := Invoke(Enum::"Message Type ori"::"ODBC.Query.Run", '{"source":"XODBCMSG","sql":"SELECT short FROM demo","output":"staged"}');
        UnbindSubscription(CapStub);
        // [THEN] It fails with LimitExceeded naming the size and the limit, with a nextStep.
        AssertProblem(Reply, 'LimitExceeded');
        Assert.IsTrue(Reply.GetText('error').Contains(Format(1024)), 'Message names the limit: ' + Reply.GetText('error'));
        Assert.IsTrue(Reply.GetText('error').Contains(Format(StrLen(ExpectedText))), 'Message names the size: ' + Reply.GetText('error'));
        Assert.IsTrue(Reply.GetText('nextStep') <> '', 'nextStep present');
    end;

    /// <summary>Builds an agent result of RowCount rows with one 10-character column, serialized exactly as the handler stages it.</summary>
    local procedure ShortRowsResult(RowCount: Integer) Body: Text
    var
        Row: JsonObject;
        Rows: JsonArray;
        Payload: JsonObject;
        Index: Integer;
    begin
        Row.Add('short', PadStr('', 10, 'y'));
        for Index := 1 to RowCount do
            Rows.Add(Row.Clone());
        Payload.Add('columns', CreateColumns('short'));
        Payload.Add('rows', Rows);
        Payload.WriteTo(Body);
    end;

    local procedure VerifyInvalidOutput()
    var
        Reply: JsonObject;
    begin
        // [WHEN] output is an unknown value or not a string.
        Reply := Invoke(Enum::"Message Type ori"::"ODBC.Query.Run", '{"source":"XODBCMSG","sql":"SELECT 1","output":"file"}');
        // [THEN] The request is refused before transport.
        AssertProblem(Reply, 'InvalidParameter');
        Reply := Invoke(Enum::"Message Type ori"::"ODBC.Query.Run", '{"source":"XODBCMSG","sql":"SELECT 1","output":true}');
        AssertProblem(Reply, 'InvalidParameter');
        AssertCalls(0);
    end;

    local procedure VerifyStagingIdIsolation()
    var
        BlobStaging: Codeunit "Blob Staging ori";
        Reply: JsonObject;
        StagingId: Guid;
        StagedText: Text;
        ContentType: Text;
        FileName: Text;
    begin
        // [GIVEN] A staged result owned by the current user.
        Mock.SetResponse(BinaryResultLbl);
        Reply := Invoke(Enum::"Message Type ori"::"ODBC.Query.Run", '{"source":"XODBCMSG","sql":"SELECT id FROM demo","output":"staged"}');
        AssertSuccess(Reply);
        Evaluate(StagingId, Reply.GetText('stagingId'));
        // [THEN] The owner resolves it; an id the user does not own does not resolve.
        Assert.IsTrue(BlobStaging.Exists(StagingId), 'Owner can read the staging row');
        Assert.IsFalse(BlobStaging.Exists(CreateGuid()), 'An id not owned by the user is not readable');
        // [THEN] Taking it consumes it, so a second reader cannot use it.
        TakeStaged(Reply, StagedText, ContentType, FileName);
        Assert.IsFalse(BlobStaging.Exists(StagingId), 'Consumed row is gone');
    end;

    local procedure TakeStaged(Reply: JsonObject; var Content: Text; var ContentType: Text; var FileName: Text): BigInteger
    var
        BlobStaging: Codeunit "Blob Staging ori";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        StagingId: Guid;
    begin
        Assert.IsTrue(Evaluate(StagingId, Reply.GetText('stagingId')), 'stagingId is a GUID');
        Assert.IsTrue(BlobStaging.Take(StagingId, TempBlob, ContentType, FileName), 'Staging row readable by its creator');
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        InStr.Read(Content);
        exit(TempBlob.Length());
    end;

    local procedure CreateColumns(Name: Text) Columns: JsonArray
    begin
        Columns.Add(Name);
    end;

    local procedure VerifyContracts()
    var
        Contracts: Codeunit "Msg Contract Mgt ori";
        MessageType: Enum "Message Type ori";
        Implementation: Interface "Msg Interface ori";
        Contract: JsonObject;
        Token: JsonToken;
        Ordinal: Integer;
        ContractText: Text;
    begin
        for Ordinal := 10035517 to 10035520 do begin
            MessageType := Enum::"Message Type ori".FromInteger(Ordinal);
            Implementation := MessageType;
            Assert.AreEqual(Enum::"Msg Direction ori"::Outbound, Implementation.GetMessageDirection(), 'Read direction');
            Assert.IsTrue(Implementation.GetDescription() <> '', 'Localized description');
            Contracts.GetContract(MessageType, Contract);
            Assert.IsTrue(Contract.Get('parameters', Token), 'Parameters chapter');
            Assert.IsTrue(Contract.Get('response', Token), 'Response chapter');
            Assert.IsTrue(Contract.Get('errors', Token), 'Errors chapter');
            Assert.AreEqual('read', Contract.GetObject('effect').GetText('effect'), 'Read effect');
            Assert.AreEqual('POST /queues', Contract.GetObject('envelope').GetText('endpoint'), 'Queued contract');
            Assert.IsTrue(Contract.Contains('metering'), 'Foundation metering');
            AssertNoSecrets(Contract.AsToken());
            Clear(Contract);
        end;
        // Story #18: the query contract declares output, the staged response fields and the playbook workflow.
        Contracts.GetContract(Enum::"Message Type ori"::"ODBC.Query.Run", Contract);
        Contract.WriteTo(ContractText);
        Assert.IsTrue(ContractText.Contains('"output"'), 'output parameter');
        Assert.IsTrue(ContractText.Contains('"stagingId"'), 'stagingId response field');
        Assert.IsTrue(ContractText.Contains('"byteSize"'), 'byteSize response field');
        Assert.IsTrue(ContractText.Contains('LimitExceeded'), 'Size cap error');
        Assert.IsTrue(ContractText.Contains('@10.stagingId'), 'Playbook reference in workflow');
    end;

    local procedure VerifySourceList()
    var
        Source: Record "ODBC Source ori";
        Reply: JsonObject;
        Item: JsonToken;
        Found: Boolean;
    begin
        Source.Get('XODBCMSG');
        Source.Blocked := true;
        Source.Description := FakeConnectionLbl;
        Source.Modify();
        Reply := Invoke(Enum::"Message Type ori"::"ODBC.Source.List", '{}');
        AssertSuccess(Reply);
        foreach Item in Reply.GetArray('sources') do
            if Item.AsObject().GetText('code') = 'XODBCMSG' then begin
                Found := true;
                Assert.IsTrue(Item.AsObject().GetBoolean('blocked'), 'Blocked sources remain discoverable');
                Assert.IsTrue(Item.AsObject().GetBoolean('readOnly'), 'Read-only policy');
                Assert.IsFalse(Item.AsObject().Contains('connectionString'), 'Never expose connection');
            end;
        Assert.IsTrue(Found, 'Fixture source listed');
        AssertCalls(0);
    end;

    local procedure VerifySourceTest()
    var
        Source: Record "ODBC Source ori";
        Reply: JsonObject;
        Request: JsonObject;
    begin
        Mock.SetResponse('{"driverName":"Mock ODBC","dbmsName":"MockDB","dbmsVersion":"1.0"}');
        Reply := Invoke(Enum::"Message Type ori"::"ODBC.Source.Test", '{"source":"XODBCMSG"}');
        AssertSuccess(Reply);
        Assert.AreEqual('MockDB', Reply.GetText('dbmsName'), 'DBMS');
        Assert.AreEqual('Mock ODBC', Reply.GetText('driverName'), 'Driver');
        Assert.IsTrue(Reply.GetInteger('roundTripMs') >= 0, 'Round trip');
        Source.Get('XODBCMSG');
        Assert.AreEqual('MockDB', Source."DBMS Name", 'Cached identity');
        Mock.GetRequest(Request);
        Assert.IsTrue(Request.GetBoolean('readOnly'), 'Test uses read only');
    end;

    local procedure VerifySchema()
    var
        Reply: JsonObject;
        Request: JsonObject;
    begin
        Mock.SetResponse('{"dbmsName":"MockDB","objects":[{"name":"demo","type":"TABLE","columns":[{"name":"id","type":"INTEGER","nullable":false}]}]}');
        Reply := Invoke(Enum::"Message Type ori"::"ODBC.Schema.Get", '{"source":"XODBCMSG","objectFilter":"demo"}');
        AssertSuccess(Reply);
        Assert.AreEqual('MockDB', Reply.GetText('dbmsName'), 'Dialect');
        Assert.AreEqual(1, Reply.GetArray('objects').Count(), 'Catalog');
        Mock.GetRequest(Request);
        Assert.AreEqual('demo', Request.GetText('objectFilter'), 'Separate catalog filter');
        Assert.IsTrue(Request.GetBoolean('readOnly'), 'Schema read only');
    end;

    local procedure VerifyQuery()
    var
        Source: Record "ODBC Source ori";
        Reply: JsonObject;
        Request: JsonObject;
        Mode: Integer;
        NullToken: JsonToken;
    begin
        for Mode := 0 to 1 do begin
            Source.Get('XODBCMSG');
            Source."Read Only" := Mode = 0;
            Source.Modify();
            Mock.Reset();
            Mock.SetResponse('{"columns":["id","empty"],"rows":[{"id":7,"empty":null}]}');
            Reply := Invoke(Enum::"Message Type ori"::"ODBC.Query.Run", '{"source":"XODBCMSG","sql":"SELECT id, empty FROM demo WHERE id = ? AND title = ?","parameters":[7,"sample"],"maxRows":2}');
            AssertSuccess(Reply);
            Assert.AreEqual(1, Reply.GetInteger('rowCount'), 'Count');
            Assert.IsTrue(Reply.GetArray('rows').GetObject(0).Get('empty', NullToken), 'Null column exists');
            Assert.IsTrue(NullToken.AsValue().IsNull(), 'Null preserved');
            Mock.GetRequest(Request);
            Assert.IsTrue(Request.GetBoolean('readOnly'), 'Always readOnly even on writable source');
            Assert.AreEqual(7, Request.GetArray('parameters').GetInteger(0), 'First positional parameter');
            Assert.AreEqual('sample', Request.GetArray('parameters').GetText(1), 'Second positional parameter');
            Assert.AreEqual(2, Request.GetInteger('rowCap'), 'Cap propagated');
            AssertCalls(1);
        end;
    end;

    local procedure VerifyEmptyRows()
    var
        Reply: JsonObject;
    begin
        Mock.SetResponse('{"columns":["id"],"rows":[]}');
        Reply := Invoke(Enum::"Message Type ori"::"ODBC.Query.Run", '{"source":"XODBCMSG","sql":"SELECT id FROM demo"}');
        AssertSuccess(Reply);
        Assert.AreEqual(0, Reply.GetInteger('rowCount'), 'Empty query');
        Assert.AreEqual('id', Reply.GetArray('columns').GetText(0), 'Empty metadata retained');
        Assert.IsFalse(Reply.GetBoolean('truncated'), 'No omitted rows');
    end;

    local procedure VerifyRowCap()
    var
        Reply: JsonObject;
        Request: JsonObject;
    begin
        Mock.SetResponse('{"rows":[{"id":1},{"id":2},{"id":3}]}');
        Reply := Invoke(Enum::"Message Type ori"::"ODBC.Query.Run", '{"source":"XODBCMSG","sql":"SELECT id FROM demo","maxRows":1}');
        AssertSuccess(Reply);
        Assert.AreEqual(1, Reply.GetInteger('rowCount'), 'Lower cap enforced locally');
        Assert.IsTrue(Reply.GetBoolean('truncated'), 'Truncated');
        Mock.GetRequest(Request);
        Assert.AreEqual(1, Request.GetInteger('rowCap'), 'Lower cap sent to transport');
        Mock.Reset();
        Reply := Invoke(Enum::"Message Type ori"::"ODBC.Query.Run", '{"source":"XODBCMSG","sql":"SELECT 1","maxRows":3}');
        AssertProblem(Reply, 'InvalidParameter');
        AssertCalls(0);
        Reply := Invoke(Enum::"Message Type ori"::"ODBC.Query.Run", '{"source":"XODBCMSG","sql":"SELECT 1","maxRows":0}');
        AssertProblem(Reply, 'InvalidParameter');
        AssertCalls(0);
    end;

    local procedure VerifyUnknownBlocked()
    var
        Source: Record "ODBC Source ori";
        MessageType: Enum "Message Type ori";
        Reply: JsonObject;
        Ordinal: Integer;
    begin
        for Ordinal := 10035518 to 10035520 do begin
            MessageType := Enum::"Message Type ori".FromInteger(Ordinal);
            Reply := Invoke(MessageType, '{"source":"XUNKNOWN"}');
            AssertProblem(Reply, 'RecordNotFound');
            Source.Get('XODBCMSG');
            Source.Blocked := true;
            Source.Modify();
            Reply := Invoke(MessageType, '{"source":"XODBCMSG"}');
            AssertProblem(Reply, 'PreconditionFailed');
            if LanguageId = 1039 then
                Assert.IsTrue(Reply.GetText('error').Contains('læst'), 'Icelandic refusal')
            else
                Assert.IsTrue(Reply.GetText('error').Contains('blocked'), 'English refusal');
            Source.Blocked := false;
            Source.Modify();
        end;
        AssertCalls(0);
    end;

    local procedure VerifyInvalidInput()
    var
        Reply: JsonObject;
    begin
        Reply := Invoke(Enum::"Message Type ori"::"ODBC.Query.Run", '{}');
        AssertProblem(Reply, 'MissingParameter');
        Reply := Invoke(Enum::"Message Type ori"::"ODBC.Query.Run", '{"source":{}}');
        AssertProblem(Reply, 'InvalidParameterFormat');
        Reply := Invoke(Enum::"Message Type ori"::"ODBC.Query.Run", '{"source":"XODBCMSG","sql":42}');
        AssertProblem(Reply, 'InvalidParameter');
        Reply := Invoke(Enum::"Message Type ori"::"ODBC.Query.Run", '{"source":"XODBCMSG","sql":"SELECT ?","parameters":{}}');
        AssertProblem(Reply, 'InvalidParameter');
        Reply := Invoke(Enum::"Message Type ori"::"ODBC.Query.Run", '{"source":"XODBCMSG","sql":"SELECT ?","parameters":[{}]}');
        AssertProblem(Reply, 'InvalidParameter');
        Reply := Invoke(Enum::"Message Type ori"::"ODBC.Schema.Get", '{"source":"XODBCMSG","objectFilter":[]}');
        AssertProblem(Reply, 'InvalidParameter');
        AssertCalls(0);
    end;

    local procedure VerifySecretResponses()
    var
        Reply: JsonObject;
    begin
        Mock.SetResponse('{"driverName":"Driver={Mock};Server=example.invalid;Password=x-unit-only;","dbmsName":"MDEyMzQ1Njc4OWFiY2RlZg==","dbmsVersion":"fake-relay-key"}');
        Reply := Invoke(Enum::"Message Type ori"::"ODBC.Source.Test", '{"source":"XODBCMSG"}');
        AssertSuccess(Reply);
        Mock.SetResponse('{"dbmsName":"MockDB","objects":[{"name":"fake-relay-key","type":"TABLE","columns":[{"name":"id","type":"MDEyMzQ1Njc4OWFiY2RlZg==","nullable":false}]}]}');
        Reply := Invoke(Enum::"Message Type ori"::"ODBC.Schema.Get", '{"source":"XODBCMSG"}');
        AssertSuccess(Reply);
        Mock.SetResponse('{"rows":[{"id":"Driver={Mock};Server=example.invalid;Password=x-unit-only;","aes":"MDEyMzQ1Njc4OWFiY2RlZg==","sas":"fake-relay-key"}]}');
        Reply := Invoke(Enum::"Message Type ori"::"ODBC.Query.Run", '{"source":"XODBCMSG","sql":"SELECT id FROM demo"}');
        AssertSuccess(Reply);
        Reply := Invoke(Enum::"Message Type ori"::"ODBC.Source.List", '{}');
        AssertSuccess(Reply);
    end;

    local procedure VerifySecretErrors()
    var
        MessageType: Enum "Message Type ori";
        Reply: JsonObject;
        Dimensions: Dictionary of [Text, Text];
        Value: Text;
        Ordinal: Integer;
    begin
        Mock.Fail();
        for Ordinal := 10035518 to 10035520 do begin
            MessageType := Enum::"Message Type ori".FromInteger(Ordinal);
            Reply := Invoke(MessageType, '{"source":"XODBCMSG","sql":"SELECT id FROM demo"}');
            AssertProblem(Reply, 'PreconditionFailed');
            Mock.GetTelemetry(Dimensions);
            foreach Value in Dimensions.Values() do
                AssertSafeText(Value);
        end;
    end;

    local procedure VerifyQuotedSql()
    var
        Reply: JsonObject;
    begin
        Mock.SetResponse('{"rows":[{"id":7}]}');
        Reply := Invoke(Enum::"Message Type ori"::"ODBC.Query.Run", '{"source":"XODBCMSG","sql":"SELECT ''DELETE; UPDATE ?'' AS title, [drop], \"update\" FROM demo WHERE id = ?","parameters":[7]}');
        AssertSuccess(Reply);
        AssertCalls(1);
    end;

    local procedure AssertRefused(SQL: Text)
    var
        Request: JsonObject;
        Reply: JsonObject;
        Body: Text;
    begin
        Request.Add('source', 'XODBCMSG');
        Request.Add('sql', SQL);
        Request.WriteTo(Body);
        Reply := Invoke(Enum::"Message Type ori"::"ODBC.Query.Run", Body);
        AssertProblem(Reply, 'InvalidParameter');
        AssertCalls(0);
    end;

    local procedure Invoke(MessageType: Enum "Message Type ori"; Body: Text) Reply: JsonObject
    var
        Dispatcher: Codeunit "Dispatcher ori";
        Request: BigText;
        Response: BigText;
        ResponseType: Text[100];
        TextResponse: Text;
    begin
        Request.AddText(Body);
        Dispatcher.Execute(MessageType, Enum::"Message Version ori"::"1.0", '', 'XODBCMSG', 'application/json', Request, Response, ResponseType, true);
        Response.GetSubText(TextResponse, 1);
        Assert.IsTrue(Reply.ReadFrom(TextResponse), 'Structured dispatch response');
        AssertNoSecrets(Reply.AsToken());
    end;

    local procedure AssertSuccess(Reply: JsonObject)
    begin
        Assert.AreEqual('Success', Reply.GetText('status'), 'Read succeeded: ' + Format(Reply));
        Assert.IsFalse(Reply.Contains('warnings'), 'Valid request has no spurious parameter warnings');
    end;

    local procedure AssertProblem(Reply: JsonObject; ExpectedCode: Text)
    begin
        Assert.AreEqual('Error', Reply.GetText('status'), 'Refusal');
        Assert.AreEqual(ExpectedCode, Reply.GetText('code'), 'Typed code');
        Assert.IsTrue(Reply.GetText('nextStep') <> '', 'Actionable next step');
    end;

    local procedure AssertCalls(Expected: Integer)
    var
        Request: JsonObject;
    begin
        Assert.AreEqual(Expected, Mock.GetRequest(Request), 'Transport invocation count');
    end;

    local procedure AssertNoSecrets(Value: JsonToken)
    var
        Serialized: Text;
    begin
        Value.WriteTo(Serialized);
        AssertSafeText(Serialized);
    end;

    local procedure AssertSafeText(Value: Text)
    begin
        Assert.IsFalse(Value.Contains('x-unit-only'), 'No password');
        Assert.IsFalse(Value.Contains('example.invalid'), 'No connection string');
        Assert.IsFalse(Value.Contains('MDEyMzQ1Njc4OWFiY2RlZg=='), 'No AES key');
        Assert.IsFalse(Value.Contains('fake-relay-key'), 'No SAS key');
    end;

    local procedure Initialize(NewLanguageId: Integer)
    var
        Setup: Record "Setup ori";
        Language: Record Language;
        Source: Record "ODBC Source ori";
        Relay: Record "ODBC Relay Connection ori";
        SecretMgt: Codeunit "ODBC Secret Mgt ori";
        SetupRef: RecordRef;
        LanguageField: FieldRef;
        Fixture: SecretText;
        FakeText: Text;
    begin
        OriginalLanguage := GlobalLanguage();
        LanguageId := NewLanguageId;
        Setup.GetRecordOnce();
        SetupRef.GetTable(Setup);
        LanguageField := SetupRef.Field(14);
        OriginalDefaultLanguage := Format(LanguageField.Value);
        Language.SetRange("Windows Language ID", LanguageId);
        Language.FindFirst();
        LanguageField.Value := Language.Code;
        SetupRef.Modify();
        GlobalLanguage(LanguageId);
        DeleteFixture();
        Mock.Reset();
        Relay.Code := 'XODBCMSG';
        Relay."Relay Namespace" := 'unit.invalid';
        Relay."Hybrid Connection Name" := 'mock';
        Relay."SAS Key Name" := 'mock';
        Relay.Insert(true);
        FakeText := 'fake-relay-key';
        Fixture := FakeText;
        SecretMgt.SetSecret(Relay.SystemId, Enum::"ODBC Secret Kind ori"::RelaySasKey, Fixture);
        Source.Code := 'XODBCMSG';
        Source."Relay Connection Code" := Relay.Code;
        Source."AES Vector" := FakeKeyLbl;
        Source.Transport := Source.Transport::Mock;
        Source."Read Only" := true;
        Source."Row Cap" := 2;
        Source."Timeout (s)" := 17;
        Source.Insert(true);
        FakeText := FakeKeyLbl;
        Fixture := FakeText;
        SecretMgt.SetSecret(Source.SystemId, Enum::"ODBC Secret Kind ori"::AesKey, Fixture);
        FakeText := FakeConnectionLbl;
        Fixture := FakeText;
        SecretMgt.SetSecret(Source.SystemId, Enum::"ODBC Secret Kind ori"::ConnectionString, Fixture);
    end;

    local procedure Cleanup()
    var
        Setup: Record "Setup ori";
        SetupRef: RecordRef;
        LanguageField: FieldRef;
    begin
        DeleteFixture();
        Mock.Reset();
        Setup.GetRecordOnce();
        SetupRef.GetTable(Setup);
        LanguageField := SetupRef.Field(14);
        LanguageField.Value := OriginalDefaultLanguage;
        SetupRef.Modify();
        GlobalLanguage(OriginalLanguage);
    end;

    local procedure DeleteFixture()
    var
        Source: Record "ODBC Source ori";
        Relay: Record "ODBC Relay Connection ori";
    begin
        if Source.Get('XODBCMSG') then
            Source.Delete(true);
        if Relay.Get('XODBCMSG') then
            Relay.Delete(true);
    end;
}
