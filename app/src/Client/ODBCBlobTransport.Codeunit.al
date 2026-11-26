namespace Origo.Bifrost.ODBC;

using System.Azure.Storage;

/// <summary>Internal blob staging. Blob identifiers are generated GUIDs, never caller-controlled URLs.</summary>
codeunit 10035510 "ODBC Blob Transport ori"
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    /// <summary>Initializes the blob client using the source's company-scoped credential.</summary>
    /// <param name="Source">Source with a configured blob container.</param>
    procedure Initialize(Source: Record "ODBC Source ori")
    var
        Container: Record "ODBC Blob Container ori";
        SecretMgt: Codeunit "ODBC Secret Mgt ori";
        Authorization: Codeunit "Storage Service Authorization";
        Secret: SecretText;
    begin
        Container.Get(Source."Blob Container Code");
        Secret := SecretMgt.GetSecret(Container.SystemId, Enum::"ODBC Secret Kind ori"::BlobSecret);
        StorageAccount := Container."Storage Account";
        ContainerName := Container."Container Name";
        if (StorageAccount = '') or (ContainerName = '') or
           (DelChr(StorageAccount, '=', 'abcdefghijklmnopqrstuvwxyz0123456789') <> '') or
           (DelChr(ContainerName, '=', 'abcdefghijklmnopqrstuvwxyz0123456789-') <> '')
        then
            Error(BlobErr);
        if Container."Auth Type" = Container."Auth Type"::AccountKey then
            BlobAuthorization := Authorization.CreateSharedKey(Secret)
        else
            BlobAuthorization := Authorization.UseReadySAS(Secret);
        BlobClient.Initialize(StorageAccount, ContainerName, BlobAuthorization);
    end;

    /// <summary>Stages a large request under a unique name.</summary>
    /// <param name="Body">JSON request.</param>
    /// <param name="FileId">Generated blob name, retained for cleanup even on failure.</param>
    procedure Upload(Body: SecretText; var FileId: Text)
    var
        Client: HttpClient;
        Request: HttpRequestMessage;
        Reply: HttpResponseMessage;
        Headers: HttpHeaders;
        Content: HttpContent;
    begin
        FileId := Format(CreateGuid(), 0, 4);
        Request.SetRequestUri('https://' + StorageAccount + '.blob.core.windows.net/' + ContainerName + '/' + FileId);
        Request.Method := 'PUT';
        Content.WriteFrom(Body);
        Content.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/json');
        Request.Content := Content;
        Request.GetHeaders(Headers);
        Headers.Add('x-ms-blob-type', 'BlockBlob');
        BlobAuthorization.Authorize(Request, StorageAccount);
        if not Client.Send(Request, Reply) then
            Error(BlobErr);
        if not Reply.IsSuccessStatusCode() then
            Error(BlobErr);
    end;

    /// <summary>Downloads a response from this configured container only.</summary>
    /// <param name="FileId">Agent's GUID blob name.</param>
    /// <param name="Body">JSON response.</param>
    procedure Download(FileId: Text; var Body: Text)
    var
        OperationResponse: Codeunit "ABS Operation Response";
        Id: Guid;
    begin
        if not Evaluate(Id, FileId) then
            Error(BlobErr);
        if FileId <> Format(Id, 0, 4) then
            Error(BlobErr);
        OperationResponse := BlobClient.GetBlobAsText(FileId, Body);
        if not OperationResponse.IsSuccessful() then
            Error(BlobErr);
    end;

    /// <summary>Best-effort removal of an ephemeral blob, including after a relay failure.</summary>
    /// <param name="FileId">Generated blob name.</param>
    [TryFunction]
    procedure TryDelete(FileId: Text)
    var
        OperationResponse: Codeunit "ABS Operation Response";
        Id: Guid;
    begin
        if FileId = '' then
            exit;
        if not Evaluate(Id, FileId) then
            exit;
        if FileId <> Format(Id, 0, 4) then
            exit;
        OperationResponse := BlobClient.DeleteBlob(FileId);
        if not OperationResponse.IsSuccessful() then
            Error(BlobErr);
    end;

    var
        BlobClient: Codeunit "ABS Blob Client";
        BlobAuthorization: Interface "Storage Service Authorization";
        StorageAccount: Text;
        ContainerName: Text;
        BlobErr: Label 'The ODBC blob transfer failed. Check the container configuration.', Comment = 'is-IS=ODBC blob-flutningur mistókst. Athugaðu uppsetningu gámsins.';
}
