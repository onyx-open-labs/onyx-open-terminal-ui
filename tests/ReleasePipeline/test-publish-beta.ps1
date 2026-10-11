$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot)
$script = Join-Path $root 'build/publish-beta.ps1'
$fixture = Join-Path $root "artifacts/release-tests-$([Guid]::NewGuid().ToString('N'))"
$inputRoot = Join-Path $fixture 'input'
$commit = '1234567890123456789012345678901234567890'
$version = '0.1.0-beta.42.1'
$runUrl = 'https://github.com/onyx-open-labs/onyx-open-terminal-ui/actions/runs/42'
foreach ($architecture in @('x64', 'x86')) {
    $candidate = Join-Path $inputRoot "beta-$architecture"
    $smoke = Join-Path $inputRoot "smoke-$architecture"
    New-Item -ItemType Directory -Force -Path $candidate, $smoke | Out-Null
    @{product='Onyx Open Terminal'; organisation='Onyx Open Labs'; licence='MIT'; version=$version;
      numericVersion='0.1.0.42'; architecture=$architecture; commit=$commit; workflow=$runUrl} |
        ConvertTo-Json | Set-Content (Join-Path $candidate 'release.json')
    @{status='PASS'; version=$version; architecture=$architecture; commit=$commit} |
        ConvertTo-Json | Set-Content (Join-Path $smoke 'result.json')
    'fixture installer bytes' | Set-Content (Join-Path $candidate "OnyxOpenTerminal-$version-$architecture-setup.exe")
    foreach ($file in @('BETA-TESTING.md', 'KNOWN-ISSUES.md', 'CHANGES.txt', 'LICENSE', 'test-results.md')) {
        "Fixture $file" | Set-Content (Join-Path $candidate $file)
    }
}
$unitTests = Join-Path $inputRoot 'unit-tests'
New-Item -ItemType Directory -Force $unitTests | Out-Null
'<TestRun />' | Set-Content (Join-Path $unitTests 'test.trx')
$arguments = @{ArtifactDirectory=$inputRoot; Commit=$commit; Repository='onyx-open-labs/onyx-open-terminal-ui'; RunUrl=$runUrl}
$output = Join-Path $fixture 'valid'
& $script @arguments -OutputDirectory $output -PrepareOnly
$plan = Get-Content (Join-Path $output 'release-plan.json') -Raw | ConvertFrom-Json
if ($plan.tag -ne "v$version" -or $plan.commit -ne $commit -or !$plan.prerelease -or $plan.assets.Count -ne 6) { throw 'Release plan identity/assets failed.' }
if (@(Get-Content (Join-Path $output 'SHA256SUMS.txt')).Count -ne 5) { throw 'Expected checksums for both installers and three archives.' }
if ((Get-Content (Join-Path $output 'release-notes.md') -Raw) -notmatch 'checks remain\s+pending') { throw 'Manual checks must remain pending in notes.' }
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::OpenRead((Join-Path $output "OnyxOpenTerminal-$version-x64-evidence.zip"))
try { if (!($zip.Entries.FullName -match 'smoke-x64/result.json')) { throw 'Smoke result missing from release evidence archive.' } } finally { $zip.Dispose() }
Write-Host 'PASS: Release plan, archives, checksums and pending manual verification notes'

function Assert-Rejected([string]$Name, [string]$Expected) {
    $caught = $false
    try { & $script @arguments -OutputDirectory (Join-Path $fixture $Name) -PrepareOnly } catch {
        if ($_.Exception.Message -notmatch $Expected) { throw }
        $caught = $true
    }
    if (!$caught) { throw "Unsafe release input was accepted: $Name" }
    Write-Host "PASS: Rejected $Name"
}
$smokeFile = Join-Path $inputRoot 'smoke-x86/result.json'
$originalSmoke = Get-Content $smokeFile -Raw
$result = $originalSmoke | ConvertFrom-Json
$result.status = 'FAIL'
$result | ConvertTo-Json | Set-Content $smokeFile
Assert-Rejected 'failed-smoke' 'Passing smoke evidence'
$result.status = 'PASS'
$result.commit = 'ffffffffffffffffffffffffffffffffffffffff'
$result | ConvertTo-Json | Set-Content $smokeFile
Assert-Rejected 'wrong-smoke-commit' 'Passing smoke evidence'
$originalSmoke | Set-Content $smokeFile
$identityFile = Join-Path $inputRoot 'beta-x86/release.json'
$originalIdentity = Get-Content $identityFile -Raw
$identity = $originalIdentity | ConvertFrom-Json
$identity.version = '0.1.0-beta.43.1'
$identity | ConvertTo-Json | Set-Content $identityFile
Assert-Rejected 'different-architecture-version' 'Candidate identity mismatch'
$originalIdentity | Set-Content $identityFile
$installer = Join-Path $inputRoot "beta-x86/OnyxOpenTerminal-$version-x86-setup.exe"
Move-Item -LiteralPath $installer -Destination "$installer.hidden"
Assert-Rejected 'missing-installer' 'Expected exactly one'
Move-Item -LiteralPath "$installer.hidden" -Destination $installer

# Mock the CLI at the process boundary; no network writes occur in these tests.
$global:releaseCliArguments = $null
$global:releaseCliExitCode = 0
$global:releaseTagReferences = '[]'
function global:gh {
    if ($args[0] -eq 'api') { $global:LASTEXITCODE = 0; return $global:releaseTagReferences }
    $global:releaseCliArguments = @($args)
    $global:LASTEXITCODE = $global:releaseCliExitCode
}
try {
    & $script @arguments -OutputDirectory (Join-Path $fixture 'mock-publication')
    $cli = $global:releaseCliArguments
    foreach ($required in @('release', 'create', "v$version", '--prerelease', '--latest=false', '--target', $commit, '--notes-file', '--repo', 'onyx-open-labs/onyx-open-terminal-ui')) {
        if ($required -notin $cli) { throw "Required publication argument missing: $required" }
    }
    if (@($cli | Where-Object { $_ -like '*.exe' -or $_ -like '*.zip' -or $_ -like '*SHA256SUMS.txt' }).Count -ne 6) { throw 'CLI did not receive all assets.' }
    $global:releaseCliExitCode = 1
    $caught = $false
    try { & $script @arguments -OutputDirectory (Join-Path $fixture 'mock-failure') } catch {
        if ($_.Exception.Message -notmatch 'publication failed') { throw }
        $caught = $true
    }
    if (!$caught) { throw 'CLI publication failure was not propagated.' }
    Write-Host 'PASS: CLI receives exact commit, prerelease flags and assets; failures propagate'
    $global:releaseTagReferences = @(@{ref="refs/tags/v$version"}) | ConvertTo-Json -AsArray
    $caught = $false
    try { & $script @arguments -OutputDirectory (Join-Path $fixture 'existing-tag') } catch {
        if ($_.Exception.Message -notmatch 'tag already exists') { throw }
        $caught = $true
    }
    if (!$caught) { throw 'Existing release tag was accepted.' }
    Write-Host 'PASS: Existing release tags are never reused or overwritten'
} finally {
    Remove-Item Function:\gh
    Remove-Variable releaseCliArguments, releaseCliExitCode, releaseTagReferences -Scope Global
    $global:LASTEXITCODE = 0
}
