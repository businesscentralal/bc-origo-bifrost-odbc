namespace Origo.Bifrost.ODBC;

using Origo.Bifrost;

/// <summary>
/// Includes the matching Bifrost ODBC permissions in the Foundation Full role.
/// </summary>
permissionsetextension 10035489 "ODBC Full Role ori" extends "BIFROST Full ori"
{
    IncludedPermissionSets = "BIFROST ODBCFull ori";
}
