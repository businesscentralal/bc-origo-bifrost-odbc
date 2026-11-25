namespace Origo.Bifrost.ODBC;

using Origo.Bifrost;

/// <summary>
/// Includes the matching Bifrost ODBC permissions in the Foundation Read role.
/// </summary>
permissionsetextension 10035490 "ODBC Read Role ori" extends "BIFROST Read ori"
{
    IncludedPermissionSets = "BIFROST ODBCRead ori";
}
