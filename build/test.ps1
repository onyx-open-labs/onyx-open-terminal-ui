param([ValidateSet('Debug', 'Release')][string]$Configuration = 'Release')
$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'build.ps1') -Configuration $Configuration
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$solution = Join-Path $PSScriptRoot '../Onyx.OpenTerminal.sln'
dotnet test $solution --configuration $Configuration --no-build
exit $LASTEXITCODE
