namespace Origo.Bifrost.ODBC.Test;

using Origo.Bifrost.ODBC;

/// <summary>Story #18: lowers the Blob Staging cap to 4096 bytes for the size-cap test.</summary>
codeunit 98142 "ODBC Staging Cap Stub ori"
{
    EventSubscriberInstance = Manual;
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ODBC Message Handler ori", 'OnGetMaxStagedBytes', '', false, false)]
    local procedure LowerCap(var MaxBytes: BigInteger)
    begin
        MaxBytes := 4096;
    end;
}
