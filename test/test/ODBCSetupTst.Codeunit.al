namespace Origo.Bifrost.ODBC.Test;

using Origo.Bifrost;
using Origo.Bifrost.ODBC;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

/// <summary>
/// Tests the ODBC setup: defaults, secret handling in IsolatedStorage, ValidateSetup and the permission sets.
/// No test calls a network or needs credentials; the secret values below are fake test strings.
/// </summary>
codeunit 98102 "ODBC Setup Tst ori"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        Assert: Codeunit "Library Assert";
        LowerPermissions: Codeunit "Library - Lower Permissions";
        SecretMgt: Codeunit "ODBC Secret Mgt ori";
        FakeSecret: SecretText;
        RelayCodeTok: Label 'TSTRELAY', Locked = true;
        BlobCodeTok: Label 'TSTBLOB', Locked = true;
        SourceCodeTok: Label 'TSTSRC', Locked = true;
        FakeSecretTok: Label 'fake-test-secret-value-1', Locked = true;
        FakeSecretText: Text;

    /// <summary>Defaults of a new source in English.</summary>
    [Test]
    procedure Scenario_AC01_SourceDefaults_English()
    begin
        VerifySourceDefaults(1033);
    end;

    /// <summary>Defaults of a new source in Icelandic.</summary>
    [Test]
    procedure Scenario_AC01_SourceDefaults_Icelandic()
    begin
        VerifySourceDefaults(1039);
    end;

    /// <summary>All fields of the three setup tables can be created and read back.</summary>
    [Test]
    procedure Scenario_AC01_AllFieldsCanBeSet()
    var
        RelayConnection: Record "ODBC Relay Connection ori";
        BlobContainer: Record "ODBC Blob Container ori";
        ODBCSource: Record "ODBC Source ori";
    begin
        // [GIVEN] Clean setup
        Initialize();

        // [WHEN] An admin creates a relay connection, a blob container and a source with all fields
        CreateRelay(RelayConnection);
        CreateBlob(BlobContainer);
        CreateSource(ODBCSource);

        // [THEN] The values are stored
        RelayConnection.Get(RelayCodeTok);
        Assert.AreEqual('ns.servicebus.windows.net', RelayConnection."Relay Namespace", 'Relay namespace');
        Assert.AreEqual('hc1', RelayConnection."Hybrid Connection Name", 'Hybrid connection name');
        Assert.AreEqual('RootKey', RelayConnection."SAS Key Name", 'SAS key name');
        BlobContainer.Get(BlobCodeTok);
        Assert.AreEqual('acct1', BlobContainer."Storage Account", 'Storage account');
        Assert.AreEqual('cont1', BlobContainer."Container Name", 'Container');
        Assert.AreEqual(Enum::"ODBC Blob Auth Type ori"::AccountKey, BlobContainer."Auth Type", 'Auth type');
        ODBCSource.Get(SourceCodeTok);
        Assert.AreEqual(RelayCodeTok, ODBCSource."Relay Connection Code", 'Relay code');
        Assert.AreEqual(BlobCodeTok, ODBCSource."Blob Container Code", 'Blob code');
        Assert.AreEqual('0123456789abcdef', ODBCSource."AES Vector", 'AES vector');
        Assert.IsFalse(ODBCSource.Blocked, 'Blocked defaults to false');

        Cleanup();
    end;

    /// <summary>Secrets live in IsolatedStorage, never in a field, and are removed with the record.</summary>
    [Test]
    procedure Scenario_AC02_SecretsOnlyInIsolatedStorage_English()
    begin
        VerifySecrets(1033);
    end;

    /// <summary>Secrets live in IsolatedStorage, never in a field, and are removed with the record (Icelandic).</summary>
    [Test]
    procedure Scenario_AC02_SecretsOnlyInIsolatedStorage_Icelandic()
    begin
        VerifySecrets(1039);
    end;

    /// <summary>An empty value removes a stored secret.</summary>
    [Test]
    procedure Scenario_AC02_EmptyValueRemovesSecret()
    var
        ODBCSource: Record "ODBC Source ori";
        Empty: SecretText;
    begin
        // [GIVEN] A source with a connection string
        Initialize();
        CreateSource(ODBCSource);
        SecretMgt.SetSecret(ODBCSource.SystemId, Enum::"ODBC Secret Kind ori"::ConnectionString, FakeSecret);
        Assert.IsTrue(SecretMgt.HasSecret(ODBCSource.SystemId, Enum::"ODBC Secret Kind ori"::ConnectionString), 'Secret should be stored.');

        // [WHEN] An empty value is stored
        SecretMgt.SetSecret(ODBCSource.SystemId, Enum::"ODBC Secret Kind ori"::ConnectionString, Empty);

        // [THEN] The secret is gone
        Assert.IsFalse(SecretMgt.HasSecret(ODBCSource.SystemId, Enum::"ODBC Secret Kind ori"::ConnectionString), 'Empty value should remove the secret.');
        Cleanup();
    end;

    /// <summary>A blocked source is reported in English.</summary>
    [Test]
    procedure Scenario_AC03_BlockedSource_English()
    begin
        VerifyBlocked(1033, 'is blocked');
    end;

    /// <summary>A blocked source is reported in Icelandic.</summary>
    [Test]
    procedure Scenario_AC03_BlockedSource_Icelandic()
    begin
        VerifyBlocked(1039, 'læst');
    end;

    /// <summary>The missing part "NoRelay" is named (English).</summary>
    [Test]
    procedure Scenario_AC03_MissingNoRelay_English()
    begin
        VerifyMissingPart(1033, 1);
    end;

    /// <summary>The missing part "NoRelay" is named (Icelandic).</summary>
    [Test]
    procedure Scenario_AC03_MissingNoRelay_Icelandic()
    begin
        VerifyMissingPart(1039, 1);
    end;

    /// <summary>The missing part "RelaySasKey" is named (English).</summary>
    [Test]
    procedure Scenario_AC03_MissingRelaySasKey_English()
    begin
        VerifyMissingPart(1033, 2);
    end;

    /// <summary>The missing part "RelaySasKey" is named (Icelandic).</summary>
    [Test]
    procedure Scenario_AC03_MissingRelaySasKey_Icelandic()
    begin
        VerifyMissingPart(1039, 2);
    end;

    /// <summary>The missing part "ConnectionString" is named (English).</summary>
    [Test]
    procedure Scenario_AC03_MissingConnectionString_English()
    begin
        VerifyMissingPart(1033, 3);
    end;

    /// <summary>The missing part "ConnectionString" is named (Icelandic).</summary>
    [Test]
    procedure Scenario_AC03_MissingConnectionString_Icelandic()
    begin
        VerifyMissingPart(1039, 3);
    end;

    /// <summary>The missing part "AesKey" is named (English).</summary>
    [Test]
    procedure Scenario_AC03_MissingAesKey_English()
    begin
        VerifyMissingPart(1033, 4);
    end;

    /// <summary>The missing part "AesKey" is named (Icelandic).</summary>
    [Test]
    procedure Scenario_AC03_MissingAesKey_Icelandic()
    begin
        VerifyMissingPart(1039, 4);
    end;

    /// <summary>The missing part "BlobSecret" is named (English).</summary>
    [Test]
    procedure Scenario_AC03_MissingBlobSecret_English()
    begin
        VerifyMissingPart(1033, 5);
    end;

    /// <summary>The missing part "BlobSecret" is named (Icelandic).</summary>
    [Test]
    procedure Scenario_AC03_MissingBlobSecret_Icelandic()
    begin
        VerifyMissingPart(1039, 5);
    end;

    /// <summary>A complete source validates without error.</summary>
    [Test]
    procedure Scenario_AC03_CompleteSourcePasses()
    var
        ODBCSource: Record "ODBC Source ori";
        Validation: Codeunit "ODBC Setup Validation ori";
    begin
        Initialize();
        CreateCompleteSource(ODBCSource);
        Validation.ValidateSetup(SourceCodeTok);
        Cleanup();
    end;

    /// <summary>An unknown source code is reported.</summary>
    [Test]
    procedure Scenario_AC03_UnknownSource()
    var
        Validation: Codeunit "ODBC Setup Validation ori";
    begin
        Initialize();
        asserterror Validation.ValidateSetup('NOSUCH');
        Assert.ExpectedError('NOSUCH');
    end;

    /// <summary>The Read role reads but cannot edit the setup (English).</summary>
    [Test]
    procedure Scenario_AC04_ReadRole_English()
    begin
        VerifyReadRole(1033);
    end;

    /// <summary>The Read role reads but cannot edit the setup (Icelandic).</summary>
    [Test]
    procedure Scenario_AC04_ReadRole_Icelandic()
    begin
        VerifyReadRole(1039);
    end;

    /// <summary>The Full role edits the setup (English).</summary>
    [Test]
    procedure Scenario_AC04_FullRole_English()
    begin
        VerifyFullRole(1033);
    end;

    /// <summary>The Full role edits the setup (Icelandic).</summary>
    [Test]
    procedure Scenario_AC04_FullRole_Icelandic()
    begin
        VerifyFullRole(1039);
    end;

    local procedure VerifySourceDefaults(LanguageId: Integer)
    var
        ODBCSource: Record "ODBC Source ori";
        PreviousLanguage: Integer;
    begin
        Initialize();
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        ODBCSource.Init();
        ODBCSource.Code := SourceCodeTok;
        ODBCSource.Insert(true);
        GlobalLanguage(PreviousLanguage);
        Assert.IsTrue(ODBCSource."Read Only", 'Read Only must default to true.');
        Assert.AreEqual(10000, ODBCSource."Row Cap", 'Row Cap must default to 10 000.');
        Assert.AreEqual(60, ODBCSource."Timeout (s)", 'Timeout must default to 60.');
        Assert.IsFalse(ODBCSource.Blocked, 'A new source is not blocked.');
        Cleanup();
    end;

    local procedure VerifySecrets(LanguageId: Integer)
    var
        RelayConnection: Record "ODBC Relay Connection ori";
        BlobContainer: Record "ODBC Blob Container ori";
        ODBCSource: Record "ODBC Source ori";
        RecRef: RecordRef;
        PreviousLanguage: Integer;
        RelaySystemId: Guid;
        BlobSystemId: Guid;
        SourceSystemId: Guid;
        Kind: Enum "ODBC Secret Kind ori";
    begin
        // [GIVEN] A relay, blob container and source, each with secrets
        Initialize();
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        CreateRelay(RelayConnection);
        CreateBlob(BlobContainer);
        CreateSource(ODBCSource);
        SecretMgt.SetSecret(RelayConnection.SystemId, Kind::RelaySasKey, FakeSecret);
        SecretMgt.SetSecret(BlobContainer.SystemId, Kind::BlobSecret, FakeSecret);
        SecretMgt.SetSecret(ODBCSource.SystemId, Kind::ConnectionString, FakeSecret);
        SecretMgt.SetSecret(ODBCSource.SystemId, Kind::AesKey, FakeSecret);
        RelaySystemId := RelayConnection.SystemId;
        BlobSystemId := BlobContainer.SystemId;
        SourceSystemId := ODBCSource.SystemId;

        // [THEN] The secrets are stored, and no field of any setup record contains them
        Assert.IsTrue(SecretMgt.HasSecret(RelaySystemId, Kind::RelaySasKey), 'SAS key stored');
        Assert.IsTrue(SecretMgt.HasSecret(BlobSystemId, Kind::BlobSecret), 'Blob secret stored');
        Assert.IsTrue(SecretMgt.HasSecret(SourceSystemId, Kind::ConnectionString), 'Connection string stored');
        Assert.IsTrue(SecretMgt.HasSecret(SourceSystemId, Kind::AesKey), 'AES key stored');
        RecRef.GetTable(RelayConnection);
        AssertNoSecretInFields(RecRef);
        RecRef.GetTable(BlobContainer);
        AssertNoSecretInFields(RecRef);
        RecRef.GetTable(ODBCSource);
        AssertNoSecretInFields(RecRef);

        // [WHEN] The records are deleted
        ODBCSource.Delete(true);
        BlobContainer.Delete(true);
        RelayConnection.Delete(true);
        GlobalLanguage(PreviousLanguage);

        // [THEN] The secrets are gone from IsolatedStorage
        Assert.IsFalse(SecretMgt.HasSecret(RelaySystemId, Kind::RelaySasKey), 'SAS key removed');
        Assert.IsFalse(SecretMgt.HasSecret(BlobSystemId, Kind::BlobSecret), 'Blob secret removed');
        Assert.IsFalse(SecretMgt.HasSecret(SourceSystemId, Kind::ConnectionString), 'Connection string removed');
        Assert.IsFalse(SecretMgt.HasSecret(SourceSystemId, Kind::AesKey), 'AES key removed');
    end;

    local procedure AssertNoSecretInFields(var RecRef: RecordRef)
    var
        FldRef: FieldRef;
        FieldIndex: Integer;
    begin
        for FieldIndex := 1 to RecRef.FieldCount() do begin
            FldRef := RecRef.FieldIndex(FieldIndex);
            if FldRef.Class() = FieldClass::Normal then
                Assert.IsFalse(Format(FldRef.Value()).Contains(FakeSecretTok), 'A secret must never be stored in a table field.');
        end;
    end;

    local procedure VerifyBlocked(LanguageId: Integer; ExpectedText: Text)
    var
        ODBCSource: Record "ODBC Source ori";
        Validation: Codeunit "ODBC Setup Validation ori";
        PreviousLanguage: Integer;
    begin
        Initialize();
        CreateCompleteSource(ODBCSource);
        ODBCSource.Blocked := true;
        ODBCSource.Modify();
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        asserterror Validation.ValidateSetup(SourceCodeTok);
        GlobalLanguage(PreviousLanguage);
        Assert.ExpectedError(SourceCodeTok);
        Assert.ExpectedError(ExpectedText);
        Cleanup();
    end;

    local procedure VerifyMissingPart(LanguageId: Integer; Stage: Integer)
    var
        ODBCSource: Record "ODBC Source ori";
        RelayConnection: Record "ODBC Relay Connection ori";
        BlobContainer: Record "ODBC Blob Container ori";
        Validation: Codeunit "ODBC Setup Validation ori";
        PreviousLanguage: Integer;
        MissingText: Text;
        ExpectedCode: Text;
        Kind: Enum "ODBC Secret Kind ori";
    begin
        // [GIVEN] A source that lacks exactly the part under test (stage 1 = relay, 2 = SAS key, 3 = connection string, 4 = AES key, 5 = blob secret)
        Initialize();
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        MissingText := 'is missing';
        if LanguageId = 1039 then
            MissingText := 'vantar';
        ExpectedCode := SourceCodeTok;
        CreateSource(ODBCSource);
        if Stage = 1 then begin
            MissingText := 'no relay connection';
            if LanguageId = 1039 then
                MissingText := 'enga relay-tengingu';
        end else begin
            CreateRelay(RelayConnection);
            ODBCSource."Relay Connection Code" := RelayCodeTok;
            ODBCSource.Modify();
            if Stage = 2 then
                ExpectedCode := RelayCodeTok;
            if Stage > 2 then
                SecretMgt.SetSecret(RelayConnection.SystemId, Kind::RelaySasKey, FakeSecret);
            if Stage > 3 then
                SecretMgt.SetSecret(ODBCSource.SystemId, Kind::ConnectionString, FakeSecret);
            if Stage > 4 then begin
                SecretMgt.SetSecret(ODBCSource.SystemId, Kind::AesKey, FakeSecret);
                CreateBlob(BlobContainer);
                ODBCSource."Blob Container Code" := BlobCodeTok;
                ODBCSource.Modify();
                ExpectedCode := BlobCodeTok;
            end;
        end;

        // [WHEN] The setup is validated
        asserterror Validation.ValidateSetup(SourceCodeTok);
        GlobalLanguage(PreviousLanguage);

        // [THEN] The error names the missing part
        Assert.ExpectedError(MissingText);
        Assert.ExpectedError(ExpectedCode);
    end;

    local procedure VerifyReadRole(LanguageId: Integer)
    var
        RelayConnection: Record "ODBC Relay Connection ori";
        ODBCSource: Record "ODBC Source ori";
        TestSource: Record "ODBC Source ori";
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "ODBC Message Handler ori";
        Mock: Codeunit "ODBC Mock Transport ori";
        Request: JsonObject;
        Reply: JsonObject;
        TestKey: SecretText;
        TestKeyText: Text;
        PreviousLanguage: Integer;
        CanEdit: Boolean;
        CanRead: Boolean;
    begin
        Initialize();
        CreateCompleteSource(ODBCSource);
        ODBCSource.Transport := ODBCSource.Transport::Mock;
        ODBCSource."AES Vector" := 'MDEyMzQ1Njc4OWFiY2RlZg==';
        ODBCSource.Modify();
        TestKeyText := 'MDEyMzQ1Njc4OWFiY2RlZg==';
        TestKey := TestKeyText;
        SecretMgt.SetSecret(ODBCSource.SystemId, Enum::"ODBC Secret Kind ori"::AesKey, TestKey);
        Mock.Reset();
        Mock.SetResponse('{"driverName":"Mock ODBC","dbmsName":"MockDB","dbmsVersion":"1.0"}');
        Request.Add('source', SourceCodeTok);
        TempArgument.SetRequestJson(Request);
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        LowerPermissions.SetExactPermissionSet('BIFROST ODBCRead ori');
        CanRead := TestSource.ReadPermission() and RelayConnection.ReadPermission();
        CanEdit := TestSource.WritePermission() or RelayConnection.WritePermission();
        Assert.IsTrue(TestSource.Get(SourceCodeTok), 'The Read role must read the source.');
        TestSource.Blocked := true;
        asserterror TestSource.Modify();
        // [WHEN] The read role invokes the identity cache through the message handler.
        // Direct handler call isolates table permission checks from Foundation dispatch permissions.
        Handler.Execute(Enum::"Message Type ori"::"ODBC.Source.Test", TempArgument);
        Reply := TempArgument.GetResponseJson();
        Assert.AreEqual('Success', Reply.GetText('status'), 'Read-role source test succeeds');
        TestSource.Get(SourceCodeTok);
        Assert.AreEqual('Mock ODBC', TestSource."Driver Name", 'Read-role test caches driver');
        Assert.AreEqual('MockDB', TestSource."DBMS Name", 'Read-role test caches DBMS');
        Assert.IsTrue(TestSource."Read Only", 'Cache preserves read-only control');
        Assert.IsFalse(TestSource.Blocked, 'Cache preserves blocked control');
        TestSource."Read Only" := false;
        asserterror TestSource.Modify();
        Assert.IsFalse(TestSource.WritePermission(), 'Cache grants no write permission to its caller');
        LowerPermissions.SetOutsideO365Scope();
        Mock.Reset();
        GlobalLanguage(PreviousLanguage);
        Assert.IsTrue(CanRead, 'The Read role must have read permission.');
        Assert.IsFalse(CanEdit, 'The Read role must not have write permission.');
        Cleanup();
    end;

    local procedure VerifyFullRole(LanguageId: Integer)
    var
        TestSource: Record "ODBC Source ori";
        PreviousLanguage: Integer;
        CanEdit: Boolean;
    begin
        Initialize();
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        LowerPermissions.SetExactPermissionSet('BIFROST ODBCFull ori');
        CanEdit := TestSource.WritePermission();
        TestSource.Init();
        TestSource.Code := SourceCodeTok;
        TestSource.Insert(true);
        TestSource.Description := 'edited';
        TestSource.Modify(true);
        LowerPermissions.SetOutsideO365Scope();
        GlobalLanguage(PreviousLanguage);
        Assert.IsTrue(CanEdit, 'The Full role must have write permission.');
        Cleanup();
    end;

    local procedure CreateRelay(var RelayConnection: Record "ODBC Relay Connection ori")
    begin
        RelayConnection.Init();
        RelayConnection.Code := RelayCodeTok;
        RelayConnection."Relay Namespace" := 'ns.servicebus.windows.net';
        RelayConnection."Hybrid Connection Name" := 'hc1';
        RelayConnection."SAS Key Name" := 'RootKey';
        RelayConnection.Insert(true);
    end;

    local procedure CreateBlob(var BlobContainer: Record "ODBC Blob Container ori")
    begin
        BlobContainer.Init();
        BlobContainer.Code := BlobCodeTok;
        BlobContainer."Storage Account" := 'acct1';
        BlobContainer."Container Name" := 'cont1';
        BlobContainer."Auth Type" := Enum::"ODBC Blob Auth Type ori"::AccountKey;
        BlobContainer.Insert(true);
    end;

    local procedure CreateSource(var ODBCSource: Record "ODBC Source ori")
    begin
        ODBCSource.Init();
        ODBCSource.Code := SourceCodeTok;
        ODBCSource."AES Vector" := '0123456789abcdef';
        ODBCSource.Insert(true);
        if RelayExists() then
            ODBCSource."Relay Connection Code" := RelayCodeTok;
        if BlobExists() then
            ODBCSource."Blob Container Code" := BlobCodeTok;
        ODBCSource.Modify(true);
    end;

    local procedure RelayExists(): Boolean
    var
        RelayConnection: Record "ODBC Relay Connection ori";
    begin
        exit(RelayConnection.Get(RelayCodeTok));
    end;

    local procedure BlobExists(): Boolean
    var
        BlobContainer: Record "ODBC Blob Container ori";
    begin
        exit(BlobContainer.Get(BlobCodeTok));
    end;

    local procedure CreateCompleteSource(var ODBCSource: Record "ODBC Source ori")
    var
        RelayConnection: Record "ODBC Relay Connection ori";
        BlobContainer: Record "ODBC Blob Container ori";
        Kind: Enum "ODBC Secret Kind ori";
    begin
        CreateRelay(RelayConnection);
        CreateBlob(BlobContainer);
        CreateSource(ODBCSource);
        SecretMgt.SetSecret(RelayConnection.SystemId, Kind::RelaySasKey, FakeSecret);
        SecretMgt.SetSecret(BlobContainer.SystemId, Kind::BlobSecret, FakeSecret);
        SecretMgt.SetSecret(ODBCSource.SystemId, Kind::ConnectionString, FakeSecret);
        SecretMgt.SetSecret(ODBCSource.SystemId, Kind::AesKey, FakeSecret);
    end;

    local procedure Initialize()
    begin
        FakeSecretText := FakeSecretTok;
        FakeSecret := FakeSecretText;
        LowerPermissions.SetExactPermissionSet('ODBC Setup Test ori');
        Cleanup();
    end;

    local procedure Cleanup()
    var
        RelayConnection: Record "ODBC Relay Connection ori";
        BlobContainer: Record "ODBC Blob Container ori";
        ODBCSource: Record "ODBC Source ori";
    begin
        LowerPermissions.SetExactPermissionSet('ODBC Setup Test ori');
        ODBCSource.DeleteAll(true);
        BlobContainer.DeleteAll(true);
        RelayConnection.DeleteAll(true);
    end;
}
