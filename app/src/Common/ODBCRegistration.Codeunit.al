namespace Origo.Bifrost.ODBC;

using Origo.Bifrost;

/// <summary>
/// Registers Bifrost ODBC with Foundation for application discovery and setup notifications.
/// Only temporary application metadata is added; Foundation owns all setup notifications.
/// </summary>
codeunit 10035485 "ODBC Registration ori"
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"App Registry ori", OnRegisterApps, '', false, false)]
    local procedure RegisterApp(var Apps: Record "Registered App ori" temporary)
    var
        AppRegistry: Codeunit "App Registry ori";
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        AppRegistry.AddApp(Apps, AppInfo.Id(), CopyStr(AppInfo.Name(), 1, 250), 0);
    end;
}
