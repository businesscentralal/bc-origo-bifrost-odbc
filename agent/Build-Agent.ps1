[CmdletBinding()]
param(
    [string]$Dotnet = 'dotnet',
    [ValidateSet('win-x64', 'win-arm64', 'linux-x64')]
    [string]$Runtime = 'win-x64',
    [string]$OutputDirectory = (Join-Path $PSScriptRoot 'artifacts')
)

$ErrorActionPreference = 'Stop'
$project = Join-Path $PSScriptRoot 'src/Bifrost.Odbc.Agent.csproj'
$tests = Join-Path $PSScriptRoot 'tests/Bifrost.Odbc.Agent.Tests.csproj'
$sha = git -C $PSScriptRoot rev-parse HEAD
if ($LASTEXITCODE -ne 0) { throw 'Cannot determine source commit.' }
$dirty = git -C $PSScriptRoot status --porcelain
if ($LASTEXITCODE -ne 0 -or $dirty) { throw 'Commit source changes before creating a traceable build.' }

# The test machine must have the SQLite ODBC driver. No test is skipped on a missing driver.
& $Dotnet test $tests --configuration Release --logger trx --results-directory (Join-Path $OutputDirectory 'tests')
if ($LASTEXITCODE -ne 0) { throw 'Agent tests failed.' }
& $Dotnet publish $project --configuration Release --runtime $Runtime --self-contained true --output (Join-Path $OutputDirectory $Runtime)
if ($LASTEXITCODE -ne 0) { throw 'Agent publish failed.' }
@{ sourceSha = "$sha".Trim(); runtime = $Runtime; signed = $false } |
    ConvertTo-Json | Set-Content -LiteralPath (Join-Path $OutputDirectory "$Runtime/build.json") -Encoding utf8
Write-Output 'Build and tests completed. Windows output must pass the organization signing path before packaging.'
