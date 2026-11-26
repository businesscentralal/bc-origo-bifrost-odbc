namespace Origo.Bifrost.ODBC;

/// <summary>
/// Checks that an ODBC source is complete enough to be used: not blocked, with a relay connection and all required secrets.
/// </summary>
codeunit 10035502 "ODBC Setup Validation ori"
{
    Access = Public;
    InherentPermissions = X;
    InherentEntitlements = X;

    /// <summary>
    /// Raises an error that names the first missing or blocked part of the source.
    /// </summary>
    /// <param name="SourceCode">Code of the ODBC source to check.</param>
    procedure ValidateSetup(SourceCode: Code[20])
    var
        ODBCSource: Record "ODBC Source ori";
        RelayConnection: Record "ODBC Relay Connection ori";
        BlobContainer: Record "ODBC Blob Container ori";
        SecretMgt: Codeunit "ODBC Secret Mgt ori";
    begin
        if not ODBCSource.Get(SourceCode) then
            Error(SourceNotFoundErr, SourceCode);
        if ODBCSource.Blocked then
            Error(SourceBlockedErr, SourceCode);

        if ODBCSource."Relay Connection Code" = '' then
            Error(MissingRelayErr, SourceCode);
        if not RelayConnection.Get(ODBCSource."Relay Connection Code") then
            Error(RelayNotFoundErr, SourceCode, ODBCSource."Relay Connection Code");
        if RelayConnection."Relay Namespace" = '' then
            Error(MissingRelayFieldErr, RelayConnection.Code, RelayConnection.FieldCaption("Relay Namespace"));
        if RelayConnection."Hybrid Connection Name" = '' then
            Error(MissingRelayFieldErr, RelayConnection.Code, RelayConnection.FieldCaption("Hybrid Connection Name"));
        if RelayConnection."SAS Key Name" = '' then
            Error(MissingRelayFieldErr, RelayConnection.Code, RelayConnection.FieldCaption("SAS Key Name"));
        if not SecretMgt.HasSecret(RelayConnection.SystemId, Enum::"ODBC Secret Kind ori"::RelaySasKey) then
            Error(MissingSecretErr, RelayConnection.Code, Enum::"ODBC Secret Kind ori"::RelaySasKey);

        if not SecretMgt.HasSecret(ODBCSource.SystemId, Enum::"ODBC Secret Kind ori"::ConnectionString) then
            Error(MissingSecretErr, SourceCode, Enum::"ODBC Secret Kind ori"::ConnectionString);
        if not SecretMgt.HasSecret(ODBCSource.SystemId, Enum::"ODBC Secret Kind ori"::AesKey) then
            Error(MissingSecretErr, SourceCode, Enum::"ODBC Secret Kind ori"::AesKey);
        if ODBCSource."AES Vector" = '' then
            Error(MissingRelayFieldErr, SourceCode, ODBCSource.FieldCaption("AES Vector"));

        if ODBCSource."Blob Container Code" <> '' then begin
            if not BlobContainer.Get(ODBCSource."Blob Container Code") then
                Error(BlobNotFoundErr, SourceCode, ODBCSource."Blob Container Code");
            if not SecretMgt.HasSecret(BlobContainer.SystemId, Enum::"ODBC Secret Kind ori"::BlobSecret) then
                Error(MissingSecretErr, BlobContainer.Code, Enum::"ODBC Secret Kind ori"::BlobSecret);
        end;
    end;

    var
        SourceNotFoundErr: Label 'The ODBC source %1 does not exist.', Comment = '%1 = source code; is-IS=ODBC-uppsprettan %1 er ekki til.';
        SourceBlockedErr: Label 'The ODBC source %1 is blocked.', Comment = '%1 = source code; is-IS=ODBC-uppsprettan %1 er læst.';
        MissingRelayErr: Label 'The ODBC source %1 has no relay connection.', Comment = '%1 = source code; is-IS=ODBC-uppsprettan %1 hefur enga relay-tengingu.';
        RelayNotFoundErr: Label 'The relay connection %2 of ODBC source %1 does not exist.', Comment = '%1 = source code, %2 = relay connection code; is-IS=Relay-tengingin %2 í ODBC-uppsprettunni %1 er ekki til.';
        BlobNotFoundErr: Label 'The blob container %2 of ODBC source %1 does not exist.', Comment = '%1 = source code, %2 = blob container code; is-IS=Blob-gámurinn %2 í ODBC-uppsprettunni %1 er ekki til.';
        MissingRelayFieldErr: Label '%1 is missing the value for %2.', Comment = '%1 = record code, %2 = field caption; is-IS=%1 vantar gildi fyrir %2.';
        MissingSecretErr: Label '%1 is missing the secret "%2".', Comment = '%1 = record code, %2 = secret kind; is-IS=%1 vantar leyndarmálið "%2".';
}
