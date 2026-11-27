namespace Origo.Bifrost.ODBC.Test;

using Origo.Bifrost;
using Origo.Bifrost.ODBC;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

/// <summary>
/// Tests that the ODBC setup is reachable from the Related menu of the Bifröst page.
/// </summary>
codeunit 98142 "ODBC Bifrost Tst ori"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        Assert: Codeunit "Library Assert";
        LowerPermissions: Codeunit "Library - Lower Permissions";
        SourcesOpened: Boolean;

    /// <summary>The action exists, is visible and enabled on the Bifröst page, in English.</summary>
    [Test]
    procedure Scenario_AC03_ActionExists_English()
    begin
        VerifyActionExists(1033);
    end;

    /// <summary>The action exists, is visible and enabled on the Bifröst page, in Icelandic.</summary>
    [Test]
    procedure Scenario_AC03_ActionExists_Icelandic()
    begin
        VerifyActionExists(1039);
    end;

    /// <summary>Invoking the action opens the ODBC sources page, in English.</summary>
    [Test]
    [HandlerFunctions('SourcesHandler')]
    procedure Scenario_AC03_ActionOpensSetup_English()
    begin
        VerifyActionOpensSetup(1033);
    end;

    /// <summary>Invoking the action opens the ODBC sources page, in Icelandic.</summary>
    [Test]
    [HandlerFunctions('SourcesHandler')]
    procedure Scenario_AC03_ActionOpensSetup_Icelandic()
    begin
        VerifyActionOpensSetup(1039);
    end;

    local procedure VerifyActionExists(LanguageId: Integer)
    var
        BifrostPage: TestPage "Bifrost ori";
        PreviousLanguage: Integer;
    begin
        // [GIVEN] The session language
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        LowerPermissions.AddPermissionSet('BIFROST ODBCRead ori');

        // [WHEN] The Bifröst page is opened
        BifrostPage.OpenView();

        // [THEN] The ODBC setup action is there
        Assert.IsTrue(BifrostPage.ODBCSetup.Visible(), 'ODBC setup action should be visible.');
        Assert.IsTrue(BifrostPage.ODBCSetup.Enabled(), 'ODBC setup action should be enabled.');
        BifrostPage.Close();
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure VerifyActionOpensSetup(LanguageId: Integer)
    var
        BifrostPage: TestPage "Bifrost ori";
        PreviousLanguage: Integer;
    begin
        // [GIVEN] The Bifröst page in the session language
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        LowerPermissions.AddPermissionSet('BIFROST ODBCRead ori');
        SourcesOpened := false;
        BifrostPage.OpenView();

        // [WHEN] The ODBC setup action is invoked
        BifrostPage.ODBCSetup.Invoke();

        // [THEN] The ODBC sources page opened
        Assert.IsTrue(SourcesOpened, 'The action should open the ODBC sources page.');
        BifrostPage.Close();
        GlobalLanguage(PreviousLanguage);
    end;

    [PageHandler]
    procedure SourcesHandler(var ODBCSources: TestPage "ODBC Sources ori")
    begin
        SourcesOpened := true;
        ODBCSources.Close();
    end;
}
