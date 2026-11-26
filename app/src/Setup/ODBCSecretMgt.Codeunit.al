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

    /// <summary>Reads a secret for the internal transport only.</summary>
    /// <param name="OwnerId">Owner of the secret.</param>
    /// <param name="SecretKind">Kind of secret.</param>
    /// <returns>The secret without exposing plain text.</returns>
    [NonDebuggable]
    procedure GetSecret(OwnerId: Guid; SecretKind: Enum "ODBC Secret Kind ori") Value: SecretText
    begin
        if not IsolatedStorage.Get(StorageKey(OwnerId, SecretKind), DataScope::Company, Value) then
            Clear(Value);
    end;

    /// <summary>Removes stored secrets from an untrusted diagnostic before it can leave the app.</summary>
    /// <param name="Source">Source whose secrets must be removed.</param>
    /// <param name="Message">Untrusted diagnostic.</param>
    /// <returns>A diagnostic with secret values removed.</returns>
    [NonDebuggable]
    procedure Redact(Source: Record "ODBC Source ori"; Message: Text): Text
    var
        Relay: Record "ODBC Relay Connection ori";
        Blob: Record "ODBC Blob Container ori";
        Kind: Enum "ODBC Secret Kind ori";
        Ordinal: Integer;
    begin
        foreach Ordinal in Kind.Ordinals() do begin
            Kind := Enum::"ODBC Secret Kind ori".FromInteger(Ordinal);
            Message := RedactValue(Message, GetSecretText(Source.SystemId, Kind));
            if Relay.Get(Source."Relay Connection Code") then
                Message := RedactValue(Message, GetSecretText(Relay.SystemId, Kind));
            if Blob.Get(Source."Blob Container Code") then
                Message := RedactValue(Message, GetSecretText(Blob.SystemId, Kind));
        end;
        exit(Message);
    end;

    /// <summary>Encrypts a stored connection string to wire-format base64 without exposing it to callers.</summary>
    /// <param name="Source">Source with base64 AES key and vector.</param>
    /// <returns>AES-CBC/PKCS7 ciphertext only.</returns>
    [NonDebuggable]
    procedure EncryptConnection(Source: Record "ODBC Source ori"): Text
    var
        Cipher: Codeunit System.Security.Encryption."Rijndael Cryptography";
    begin
        Cipher.InitRijndaelProvider();
        Cipher.SetBlockSize(128);
        Cipher.SetCipherMode('CBC');
        Cipher.SetPaddingMode('PKCS7');
        Cipher.SetEncryptionData(GetSecret(Source.SystemId, Enum::"ODBC Secret Kind ori"::AesKey), Source."AES Vector");
        exit(Cipher.Encrypt(GetSecretText(Source.SystemId, Enum::"ODBC Secret Kind ori"::ConnectionString)));
    end;

    [NonDebuggable]
    local procedure GetSecretText(OwnerId: Guid; SecretKind: Enum "ODBC Secret Kind ori") Value: Text
    begin
        // Plain text is confined to encryption and redaction inside this non-debuggable codeunit.
        if not IsolatedStorage.Get(StorageKey(OwnerId, SecretKind), DataScope::Company, Value) then
            Clear(Value);
    end;

    [NonDebuggable]
    local procedure RedactValue(Message: Text; Value: Text): Text
    begin
        if Value <> '' then
            exit(Message.Replace(Value, '[redacted]'));
        exit(Message);
    end;

    local procedure StorageKey(OwnerId: Guid; SecretKind: Enum "ODBC Secret Kind ori"): Text
    begin
        exit(StrSubstNo(KeyTok, DelChr(Format(OwnerId), '=', '{}'), SecretKind.AsInteger()));
    end;

    var
        KeyTok: Label 'ODBC-%1-%2', Locked = true;
}
