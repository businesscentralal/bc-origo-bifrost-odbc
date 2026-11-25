namespace Origo.Bifrost.ODBC;

/// <summary>
/// Keeps ODBC setup secrets in company-scoped IsolatedStorage, keyed by the record SystemId and the secret kind.
/// No procedure of this codeunit is public: secrets can be set, tested for presence and deleted,
/// but only the app's own transport (later stories) may read them.
/// </summary>
codeunit 10035501 "ODBC Secret Mgt ori"
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    /// <summary>Stores a secret; an empty value removes it.</summary>
    /// <param name="OwnerId">SystemId of the setup record that owns the secret.</param>
    /// <param name="SecretKind">Which secret of the record.</param>
    /// <param name="Value">The secret value.</param>
    procedure SetSecret(OwnerId: Guid; SecretKind: Enum "ODBC Secret Kind ori"; Value: SecretText)
    begin
        if Value.IsEmpty() then begin
            DeleteSecret(OwnerId, SecretKind);
            exit;
        end;
        IsolatedStorage.Set(StorageKey(OwnerId, SecretKind), Value, DataScope::Company);
    end;

    /// <summary>Returns whether the secret is stored. The value itself is never returned.</summary>
    /// <param name="OwnerId">SystemId of the setup record that owns the secret.</param>
    /// <param name="SecretKind">Which secret of the record.</param>
    /// <returns>True when a secret is stored.</returns>
    procedure HasSecret(OwnerId: Guid; SecretKind: Enum "ODBC Secret Kind ori"): Boolean
    begin
        if IsNullGuid(OwnerId) then
            exit(false);
        exit(IsolatedStorage.Contains(StorageKey(OwnerId, SecretKind), DataScope::Company));
    end;

    /// <summary>Removes one secret.</summary>
    /// <param name="OwnerId">SystemId of the setup record that owns the secret.</param>
    /// <param name="SecretKind">Which secret of the record.</param>
    procedure DeleteSecret(OwnerId: Guid; SecretKind: Enum "ODBC Secret Kind ori")
    begin
        if HasSecret(OwnerId, SecretKind) then
            IsolatedStorage.Delete(StorageKey(OwnerId, SecretKind), DataScope::Company);
    end;

    /// <summary>Removes every secret of a record, called when the record is deleted.</summary>
    /// <param name="OwnerId">SystemId of the setup record that owns the secrets.</param>
    procedure DeleteAllSecrets(OwnerId: Guid)
    var
        SecretKind: Enum "ODBC Secret Kind ori";
        KindOrdinal: Integer;
    begin
        foreach KindOrdinal in SecretKind.Ordinals() do begin
            SecretKind := Enum::"ODBC Secret Kind ori".FromInteger(KindOrdinal);
            DeleteSecret(OwnerId, SecretKind);
        end;
    end;

    local procedure StorageKey(OwnerId: Guid; SecretKind: Enum "ODBC Secret Kind ori"): Text
    begin
        exit(StrSubstNo(KeyTok, DelChr(Format(OwnerId), '=', '{}'), SecretKind.AsInteger()));
    end;

    var
        KeyTok: Label 'ODBC-%1-%2', Locked = true;
}
