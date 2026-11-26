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

    /// <summary>Removes every exact stored secret from a bounded, untrusted diagnostic without unwrapping credentials.</summary>
    /// <param name="Source">Source whose secrets must be removed.</param>
    /// <param name="Message">Untrusted diagnostic.</param>
    /// <returns>A redacted diagnostic, or a localized safe fallback for oversized diagnostics.</returns>
    [NonDebuggable]
    procedure Redact(Source: Record "ODBC Source ori"; Message: Text): Text
    var
        Result: Text;
    begin
        // Never truncate an untrusted diagnostic: truncation might expose part of a longer secret.
        if StrLen(Message) > MaxScanLength() then
            exit(SafeDiagnosticErr);
        Result := RemoveSecrets(Source, Message);
        // Partial connection-string fields and URLs are not safe diagnostics either.
        if Result.Contains('=') or Result.Contains('://') then
            exit(SafeDiagnosticErr);
        exit(Result);
    end;

    /// <summary>Removes every exact stored secret from a data value and returns all other content unchanged.</summary>
    /// <remarks>Unlike Redact, data values keep URLs, key=value text and long text; only stored secrets become [redacted].</remarks>
    /// <param name="Source">Source whose secrets must be removed.</param>
    /// <param name="Value">Data value returned by the agent (cell, column, catalogue or identity text).</param>
    /// <returns>The value with each exact stored secret replaced by [redacted].</returns>
    [NonDebuggable]
    procedure RedactValue(Source: Record "ODBC Source ori"; Value: Text): Text
    begin
        exit(RemoveSecrets(Source, Value));
    end;

    [NonDebuggable]
    local procedure RemoveSecrets(Source: Record "ODBC Source ori"; Message: Text): Text
    var
        Relay: Record "ODBC Relay Connection ori";
        Blob: Record "ODBC Blob Container ori";
        Cryptography: Codeunit System.Security.Encryption."Cryptography Management";
        Kind: Enum "ODBC Secret Kind ori";
        Fingerprints: List of [Text];
        Ordinal: Integer;
        StartIndex: Integer;
        EndIndex: Integer;
        LastIndex: Integer;
        MatchLength: Integer;
        Candidate: Text;
        Result: Text;
        CandidateSecret: SecretText;
    begin
        if Message = '' then
            exit(Message);
        foreach Ordinal in Kind.Ordinals() do begin
            Kind := Enum::"ODBC Secret Kind ori".FromInteger(Ordinal);
            AddFingerprint(GetSecret(Source.SystemId, Kind), Fingerprints);
            if Relay.Get(Source."Relay Connection Code") then
                AddFingerprint(GetSecret(Relay.SystemId, Kind), Fingerprints);
            if Blob.Get(Source."Blob Container Code") then
                AddFingerprint(GetSecret(Blob.SystemId, Kind), Fingerprints);
        end;
        if Fingerprints.Count() = 0 then
            exit(Message);
        // A value that is exactly a stored secret of any length is always removed.
        CandidateSecret := Message;
        if Fingerprints.Contains(Cryptography.GenerateHashAsBase64String('ODBC diagnostic comparison v1', CandidateSecret, 2)) then
            exit(RedactedTok);
        StartIndex := 1;
        while StartIndex <= StrLen(Message) do begin
            MatchLength := 0;
            // Embedded secrets are matched up to MaxScanLength characters: at most 256 candidates per position.
            // HMAC equality compares secret keys without obtaining their plaintext or length.
            LastIndex := StartIndex + MaxScanLength() - 1;
            if LastIndex > StrLen(Message) then
                LastIndex := StrLen(Message);
            for EndIndex := LastIndex downto StartIndex do
                if MatchLength = 0 then begin
                    Candidate := CopyStr(Message, StartIndex, EndIndex - StartIndex + 1);
                    CandidateSecret := Candidate;
                    if Fingerprints.Contains(Cryptography.GenerateHashAsBase64String('ODBC diagnostic comparison v1', CandidateSecret, 2)) then
                        MatchLength := EndIndex - StartIndex + 1;
                end;
            if MatchLength > 0 then begin
                Result += RedactedTok;
                StartIndex += MatchLength;
            end else begin
                Result += CopyStr(Message, StartIndex, 1);
                StartIndex += 1;
            end;
        end;
        exit(Result);
    end;

    local procedure MaxScanLength(): Integer
    begin
        exit(256);
    end;

    [NonDebuggable]
    local procedure AddFingerprint(Value: SecretText; var Fingerprints: List of [Text])
    var
        Cryptography: Codeunit System.Security.Encryption."Cryptography Management";
    begin
        if not Value.IsEmpty() then
            Fingerprints.Add(Cryptography.GenerateHashAsBase64String('ODBC diagnostic comparison v1', Value, 2));
    end;

    /// <summary>Encrypts the connection string while retaining SecretText protection through the wire boundary.</summary>
    /// <param name="Source">Source with base64 AES key and vector.</param>
    /// <returns>AES-CBC/PKCS7 ciphertext as SecretText.</returns>
    [NonDebuggable]
    procedure EncryptConnection(Source: Record "ODBC Source ori"): SecretText
    var
        Cipher: Codeunit System.Security.Encryption."Rijndael Cryptography";
    begin
        Cipher.InitRijndaelProvider();
        Cipher.SetBlockSize(128);
        Cipher.SetCipherMode('CBC');
        Cipher.SetPaddingMode('PKCS7');
        Cipher.SetEncryptionData(GetSecret(Source.SystemId, Enum::"ODBC Secret Kind ori"::AesKey), Source."AES Vector");
        exit(Cipher.Encrypt(GetSecret(Source.SystemId, Enum::"ODBC Secret Kind ori"::ConnectionString)));
    end;

    local procedure StorageKey(OwnerId: Guid; SecretKind: Enum "ODBC Secret Kind ori"): Text
    begin
        exit(StrSubstNo(KeyTok, DelChr(Format(OwnerId), '=', '{}'), SecretKind.AsInteger()));
    end;

    var
        SafeDiagnosticErr: Label 'The ODBC request failed. The agent diagnostic contained sensitive or oversized content.', Comment = 'is-IS=ODBC-beiðni mistókst. Greining miðlarans innihélt viðkvæmt eða of stórt efni.';
        KeyTok: Label 'ODBC-%1-%2', Locked = true;
        RedactedTok: Label '[redacted]', Locked = true;
}
