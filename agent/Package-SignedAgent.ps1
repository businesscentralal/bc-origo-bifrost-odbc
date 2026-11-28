[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PublishDirectory,
    [Parameter(Mandatory)][string]$Destination
)

$ErrorActionPreference = 'Stop'
$manifestFile = Join-Path $PublishDirectory 'build.json'
$manifest = Get-Content -LiteralPath $manifestFile -Raw | ConvertFrom-Json
if ($manifest.sourceSha -notmatch '^[a-f0-9]{40}$' -or $manifest.runtime -notmatch '^win-(x64|arm64)$') {
    throw 'A Windows build manifest with a full source commit is required.'
}
foreach ($name in @('Bifrost.Odbc.Agent.exe', 'Bifrost.Odbc.Agent.dll')) {
    $file = Join-Path $PublishDirectory $name
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw 'Required Windows agent file is missing.' }
    $signature = Get-AuthenticodeSignature -LiteralPath $file
    if ($signature.Status -ne 'Valid') { throw 'Agent Authenticode signature is missing or invalid.' }
}
if (Test-Path -LiteralPath $Destination) { throw 'The output archive already exists.' }
$manifest.signed = $true
$manifest | ConvertTo-Json | Set-Content -LiteralPath $manifestFile -Encoding utf8
Compress-Archive -Path (Join-Path $PublishDirectory '*') -DestinationPath $Destination
Get-FileHash -LiteralPath $Destination -Algorithm SHA256 | Select-Object Algorithm, Hash
