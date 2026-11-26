namespace Origo.Bifrost.ODBC.Test;

using System.Security.Encryption;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

/// <summary>Story #4: fixed AES-CBC/PKCS7 vectors shared with the .NET agent. Fixtures are synthetic and never connect.</summary>
codeunit 98130 "ODBC Agent Crypto Tst ori"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        Assert: Codeunit "Library Assert";
        LowerPermissions: Codeunit "Library - Lower Permissions";
        FakeKeyLbl: Label 'MDEyMzQ1Njc4OWFiY2RlZg==', Locked = true;
        FakeVectorLbl: Label 'ZmVkY2JhOTg3NjU0MzIxMA==', Locked = true;
        AsciiPlainLbl: Label 'Driver={XFixture};Database=XTest', Locked = true;
        UnicodePlainLbl: Label 'Driver={XPrófun};Database=XGögn', Locked = true;
        AsciiCipherLbl: Label '9j1leCfGlLUdYGV4MkTmt65ql1FjaTq1DXLaeCkW1TirGQG16KRkOeFvSywOevlJ', Locked = true;
        UnicodeCipherLbl: Label 'Ko+wQBf8p664txT2BRD/9CUGCx43hxvFA4iGj0mTewn/LrVDjbSeN6asq7BdpIPd', Locked = true;

    /// <summary>ASCII fixed vector in English.</summary>
    [Test]
    procedure AsciiVectorEnglish()
    begin
        VerifyVector(1033, AsciiPlainLbl, AsciiCipherLbl);
    end;

    /// <summary>ASCII fixed vector in Icelandic.</summary>
    [Test]
    procedure AsciiVectorIcelandic()
    begin
        VerifyVector(1039, AsciiPlainLbl, AsciiCipherLbl);
    end;

    /// <summary>UTF-8 non-ASCII boundary vector in English.</summary>
    [Test]
    procedure UnicodeVectorEnglish()
    begin
        VerifyVector(1033, UnicodePlainLbl, UnicodeCipherLbl);
    end;

    /// <summary>UTF-8 non-ASCII boundary vector in Icelandic.</summary>
    [Test]
    procedure UnicodeVectorIcelandic()
    begin
        VerifyVector(1039, UnicodePlainLbl, UnicodeCipherLbl);
    end;

    /// <summary>Malformed synthetic ciphertext is rejected in English.</summary>
    [Test]
    procedure InvalidCipherEnglish()
    begin
        VerifyInvalidCipher(1033);
    end;

    /// <summary>Malformed synthetic ciphertext is rejected in Icelandic.</summary>
    [Test]
    procedure InvalidCipherIcelandic()
    begin
        VerifyInvalidCipher(1039);
    end;

    local procedure VerifyVector(LanguageId: Integer; Plain: Text; Encrypted: Text)
    var
        OriginalLanguage: Integer;
        Success: Boolean;
    begin
        LowerPermissions.AddPermissionSet('ODBC Setup Test ori');
        OriginalLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Success := TryVerifyVector(Plain, Encrypted);
        GlobalLanguage(OriginalLanguage);
        Assert.IsTrue(Success, 'The BC provider must match the fixed .NET AES vector without exposing its contents.');
    end;

    [TryFunction]
    local procedure TryVerifyVector(Plain: Text; Encrypted: Text)
    var
        Cipher: Codeunit "Rijndael Cryptography";
        Cryptography: Codeunit "Cryptography Management";
        Decrypted: SecretText;
        Generated: SecretText;
        ExpectedPlain: SecretText;
        ExpectedCipher: SecretText;
        FakeAesKey: SecretText;
    begin
        Cipher.InitRijndaelProvider();
        FakeAesKey := Format(FakeKeyLbl);
        Cipher.SetEncryptionData(FakeAesKey, FakeVectorLbl);
        Decrypted := Cipher.Decrypt(Encrypted);
        Generated := Cipher.Encrypt(Plain);
        ExpectedPlain := Plain;
        ExpectedCipher := Encrypted;
        Assert.AreEqual(Cryptography.GenerateHashAsBase64String('XInterop', ExpectedPlain, 2),
            Cryptography.GenerateHashAsBase64String('XInterop', Decrypted, 2), 'The decrypted fixture must match.');
        Assert.AreEqual(Cryptography.GenerateHashAsBase64String('XInterop', ExpectedCipher, 2),
            Cryptography.GenerateHashAsBase64String('XInterop', Generated, 2), 'The encrypted fixture must match.');
    end;

    local procedure VerifyInvalidCipher(LanguageId: Integer)
    var
        Cipher: Codeunit "Rijndael Cryptography";
        Decrypted: SecretText;
        OriginalLanguage: Integer;
        FakeAesKey: SecretText;
    begin
        LowerPermissions.AddPermissionSet('ODBC Setup Test ori');
        OriginalLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Cipher.InitRijndaelProvider();
        FakeAesKey := Format(FakeKeyLbl);
        Cipher.SetEncryptionData(FakeAesKey, FakeVectorLbl);
        asserterror Decrypted := Cipher.Decrypt('X-not-base64');
        GlobalLanguage(OriginalLanguage);
        Assert.IsTrue(Decrypted.IsEmpty(), 'Invalid ciphertext must fail without returning connection data.');
        ClearLastError();
    end;
}
