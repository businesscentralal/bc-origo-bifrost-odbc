using System.Diagnostics;
using System.Reflection;
using System.Text.Json;

namespace Origo.Bifrost.Odbc.Agent;

// A process boundary bounds even drivers that ignore CommandTimeout or block in Open/GetSchema.
public interface IRequestExecutor
{
    Task<string> ExecuteAsync(Request request, string method, CancellationToken cancellationToken);
}

public sealed class RequestExecutor(Settings settings) : IRequestExecutor
{
    public async Task<string> ExecuteAsync(Request request, string method, CancellationToken cancellationToken)
    {
        request.Validate(method, settings);
        var start = new ProcessStartInfo(Environment.ProcessPath!)
        {
            UseShellExecute = false,
            RedirectStandardInput = true,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            CreateNoWindow = true
        };
        if (string.Equals(Path.GetFileNameWithoutExtension(Environment.ProcessPath), "dotnet", StringComparison.OrdinalIgnoreCase))
            start.ArgumentList.Add(Assembly.GetExecutingAssembly().Location);
        start.ArgumentList.Add("--execute-request");
        start.ArgumentList.Add(method);
        start.Environment["COMPlus_DbgEnableMiniDump"] = "0";
        using var process = Process.Start(start) ?? throw new InvalidOperationException("Cannot start request worker.");
        using var deadline = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        deadline.CancelAfter(TimeSpan.FromSeconds(request.TimeoutSeconds));
        try
        {
            // Never forward driver diagnostics from stderr to application logs.
            var discardErrors = DiscardAsync(process.StandardError.BaseStream, deadline.Token);
            var output = Protocol.ReadBoundedAsync(process.StandardOutput.BaseStream, deadline.Token);
            await process.StandardInput.WriteAsync(JsonSerializer.Serialize(request, Protocol.Json).AsMemory(), deadline.Token);
            process.StandardInput.Close();
            await process.WaitForExitAsync(deadline.Token);
            await discardErrors;
            string response = await output;
            if (process.ExitCode != 0 || response.Length == 0)
                throw new InvalidOperationException("Request worker failed.");
            using var validated = JsonDocument.Parse(response);
            return response;
        }
        finally
        {
            if (!process.HasExited)
            {
                process.Kill(entireProcessTree: true);
                await process.WaitForExitAsync(CancellationToken.None);
            }
        }
    }

    private static async Task DiscardAsync(Stream stream, CancellationToken token)
    {
        var buffer = new byte[4096];
        while (await stream.ReadAsync(buffer, token) != 0)
        {
        }
    }
}
