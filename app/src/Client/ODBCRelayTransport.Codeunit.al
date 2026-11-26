namespace Origo.Bifrost.ODBC;

using System.Security.Encryption;
using System.Utilities;

/// <summary>Azure Relay transport. SQL travels in a JSON body so dependency URLs never contain SQL or connection data.</summary>
codeunit 10035509 "ODBC Relay Transport ori" implements "ODBC Transport ori"
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    /// <summary>Sends one GET (read) or PUT (Execute) to the relay, optionally staging large bodies in Blob.</summary>
    /// <param name="Source">Validated source.</param>
    /// <param name="Operation">API operation.</param>
    /// <param name="Request">Request payload with encrypted connection string.</param>
    /// <param name="Response">Agent response JSON.</param>
    procedure Send(Source: Record "ODBC Source ori"; Operation: Text; Request: JsonObject; var Response: JsonObject)
    var
        Success: Boolean;
        CleanupSucceeded: Boolean;
    begin
        Clear(RequestFileId);
        Clear(ResponseFileId);
        Success := TrySend(Source, Operation, Request, Response);
        if Source."Blob Container Code" <> '' then begin
            CleanupSucceeded := BlobTransport.TryDelete(RequestFileId);
            CleanupSucceeded := BlobTransport.TryDelete(ResponseFileId) and CleanupSucceeded;
        end else
            CleanupSucceeded := true;
        if not Success then
            Error(TransportErr);
        if not CleanupSucceeded then
            Error(CleanupErr);
    end;

    [TryFunction]
    local procedure TrySend(Source: Record "ODBC Source ori"; Operation: Text; Request: JsonObject; var Response: JsonObject)
    var
        Relay: Record "ODBC Relay Connection ori";
        Client: HttpClient;
        Message: HttpRequestMessage;
        Reply: HttpResponseMessage;
        Headers: HttpHeaders;
        Content: HttpContent;
        Body: Text;
        Endpoint: Text;
    begin
        Relay.Get(Source."Relay Connection Code");
        ValidateEndpoint(Relay);
        Endpoint := 'https://' + Relay."Relay Namespace" + '/' + Relay."Hybrid Connection Name";
        Request.Add('operation', Operation);
        if Source."Blob Container Code" <> '' then begin
            BlobTransport.Initialize(Source);
            Request.Add('responseViaBlob', true);
        end;
        Request.WriteTo(Body);
        if (StrLen(Body) > 65536) and (Source."Blob Container Code" <> '') then begin
            BlobTransport.Upload(Body, RequestFileId);
            Clear(Request);
            Request.Add('queryFileId', RequestFileId);
            Request.Add('operation', Operation);
            Request.Add('rowCap', Source."Row Cap");
            Request.Add('timeoutSeconds', Source."Timeout (s)");
            Request.Add('readOnly', Operation <> 'Execute');
            Request.WriteTo(Body);
        end;
        Content.WriteFrom(Body);
        Content.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/json');
        Message.Content := Content;
        Message.SetRequestUri(Endpoint);
        if Operation = 'Execute' then
            Message.Method := 'PUT'
        else
            Message.Method := 'GET';
        Message.GetHeaders(Headers);
        Headers.Add('ServiceBusAuthorization', CreateAuthorization(Relay, Endpoint));
        Client.Timeout(Source."Timeout (s)" * 1000);
        if not Client.Send(Message, Reply) then
            Error(TransportErr);
        if not Reply.IsSuccessStatusCode() then
            Error(TransportErr);
        Reply.Content.ReadAs(Body);
        if not Response.ReadFrom(Body) then
            Error(TransportErr);
        if Response.Contains('queryFileId') then begin
            if Source."Blob Container Code" = '' then
                Error(TransportErr);
            ResponseFileId := Response.GetText('queryFileId');
            BlobTransport.Download(ResponseFileId, Body);
            Clear(Response);
            if not Response.ReadFrom(Body) then
                Error(TransportErr);
        end;
    end;

    local procedure ValidateEndpoint(Relay: Record "ODBC Relay Connection ori")
    var
        Uri: Codeunit Uri;
    begin
        Uri.Init('https://' + Relay."Relay Namespace" + '/' + Relay."Hybrid Connection Name");
        if (Uri.GetHost() <> Relay."Relay Namespace") or
           not Relay."Relay Namespace".EndsWith('.servicebus.windows.net') or
           (Uri.GetQuery() <> '') or (Uri.GetFragment() <> '')
        then
            Error(TransportErr);
    end;

    [NonDebuggable]
    local procedure CreateAuthorization(Relay: Record "ODBC Relay Connection ori"; Endpoint: Text): SecretText
    var
        SecretMgt: Codeunit "ODBC Secret Mgt ori";
        Cryptography: Codeunit "Cryptography Management";
        Uri: Codeunit Uri;
        SigningKey: SecretText;
        Signature: Text;
        Expiry: Text;
        SignatureInput: Text;
        NewLine: Char;
    begin
        SigningKey := SecretMgt.GetSecret(Relay.SystemId, Enum::"ODBC Secret Kind ori"::RelaySasKey);
        Expiry := Format(Round((CurrentDateTime() - CreateDateTime(19700101D, 000000T)) / 1000, 1, '<') + 600, 0, 9);
        NewLine := 10;
        SignatureInput := Uri.EscapeDataString(Endpoint) + Format(NewLine) + Expiry;
        Signature := Cryptography.GenerateHashAsBase64String(SignatureInput, SigningKey, 2);
        exit(SecretStrSubstNo('SharedAccessSignature sr=%1&sig=%2&se=%3&skn=%4', Uri.EscapeDataString(Endpoint), Uri.EscapeDataString(Signature), Expiry, Uri.EscapeDataString(Relay."SAS Key Name")));
    end;

    var
        BlobTransport: Codeunit "ODBC Blob Transport ori";
        RequestFileId: Text;
        ResponseFileId: Text;
        TransportErr: Label 'The ODBC relay request failed. Check the relay, agent and timeout settings.', Comment = 'is-IS=ODBC relay-beiðni mistókst. Athugaðu relay, miðlara og tímamörk.';
        CleanupErr: Label 'The ODBC request completed but temporary blob cleanup failed.', Comment = 'is-IS=ODBC-beiðninni lauk en hreinsun tímabundinna blob-gagna mistókst.';
}
