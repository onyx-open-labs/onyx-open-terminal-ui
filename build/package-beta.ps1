param(
    [Parameter(Mandatory)][ValidateSet('x64','x86')][string]$Architecture,
    [Parameter(Mandatory)][ValidateRange(1,65534)][int]$BuildNumber,
    [Parameter(Mandatory)][ValidateRange(1,65534)][int]$Attempt,
    [Parameter(Mandatory)][string]$Commit,
    [Parameter(Mandatory)][string]$PreviousTestCommit,
    [Parameter(Mandatory)][string]$RunUrl,
    [string]$CompilerPath = (Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6/ISCC.exe')
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot
Set-Location $root
$base = (Get-Content deploy/version.json -Raw | ConvertFrom-Json).version
if ($base -notmatch '^\d+\.\d+\.\d+$') { throw 'Expected a three-part base version.' }
$candidate = "$base-beta.$BuildNumber.$Attempt"
$numeric = "$base.$BuildNumber"
$output = Join-Path $root "artifacts/beta-$Architecture"
$publish = Join-Path $root "artifacts/publish-$Architecture"
New-Item -ItemType Directory -Force $output | Out-Null
dotnet publish src/Onyx.OpenTerminal.WinUI/Onyx.OpenTerminal.WinUI.csproj -c Release -r "win-$Architecture" --self-contained true -p:Platform=$Architecture -p:Version=$candidate -p:FileVersion=$numeric -p:Company='Onyx Open Labs' -p:Product='Onyx Open Terminal' -p:PublishTrimmed=false -o $publish
if ($LASTEXITCODE) { throw "Publish failed: $LASTEXITCODE" }
@{ product='Onyx Open Terminal'; organisation='Onyx Open Labs'; licence='MIT'; version=$candidate; numericVersion=$numeric; architecture=$Architecture; commit=$Commit; workflow=$RunUrl } | ConvertTo-Json | Set-Content "$output/release.json" -Encoding utf8
$compiler = $CompilerPath
if (!(Test-Path $compiler)) { throw 'Install Inno Setup 6 before packaging.' }
& $compiler /Q "/DPublishDir=$publish" "/DOutputDir=$output" "/DArchitecture=$Architecture" "/DCandidateVersion=$candidate" "/DNumericVersion=$numeric" deploy/installer.iss
if ($LASTEXITCODE) { throw "Installer compilation failed: $LASTEXITCODE" }
Copy-Item LICENSE, deploy/BETA-TESTING.md, deploy/KNOWN-ISSUES.md $output
git log "$PreviousTestCommit..$Commit" --pretty=format:'%h %s' | Set-Content "$output/CHANGES.txt"
if ($LASTEXITCODE) { throw 'Could not generate change summary.' }
Copy-Item deploy/test-results-template.md "$output/test-results.md"
