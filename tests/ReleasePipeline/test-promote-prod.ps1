$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot)
$fixture = Join-Path $root "artifacts/prod-tests-$([guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Force "$fixture/build", "$fixture/deploy", "$fixture/assets" | Out-Null
Copy-Item "$root/build/promote-prod.ps1", "$root/build/prepare-prod.ps1" "$fixture/build"
'{"version":"0.1.0"}' | Set-Content "$fixture/deploy/version.json"
# Mock only the external signature trust boundary; production has no skip switch.
@'
param($Path,$EvidencePath)
if ($global:rejectSignature) { throw 'Signature verification failed' }
'[]' | Set-Content $EvidencePath
'@ | Set-Content "$fixture/build/verify-signatures.ps1"
$global:prodFixture = $fixture
$global:prodMain = 'a' * 40
$global:prodTest = 'b' * 40
$global:prodHead = 'c' * 40
$global:prodMode = ''
$global:prodCalls = @()
$originalSubject = $env:SIGNING_CERTIFICATE_SUBJECT
$env:SIGNING_CERTIFICATE_SUBJECT = 'CN=Fixture publisher'
$candidate = '0.1.0-test.42.1'
$testUrl = 'https://github.com/owner/repo/actions/runs/42'
foreach ($arch in @('x64','x86')) {
    $candidateDir = "$fixture/evidence-$arch/test-$arch"
    $smokeDir = "$fixture/evidence-$arch/smoke-$arch"
    New-Item -ItemType Directory -Force $candidateDir, $smokeDir | Out-Null
    $installerName = "OnyxOpenTerminal-$candidate-$arch-setup.exe"
    'validated bytes' | Set-Content "$fixture/assets/$installerName"
    $hash = (Get-FileHash "$fixture/assets/$installerName").Hash
    @{version=$candidate;commit=$global:prodTest;architecture=$arch;workflow=$testUrl;
      product='Onyx Open Terminal';organisation='Onyx Open Labs';licence='MIT'} | ConvertTo-Json | Set-Content "$candidateDir/release.json"
    @{status='PASS';version=$candidate;commit=$global:prodTest;architecture=$arch} | ConvertTo-Json | Set-Content "$smokeDir/result.json"
    @(@{sha256=$hash}) | ConvertTo-Json -AsArray | Set-Content "$smokeDir/installer-signatures.json"
    @('Onyx.OpenTerminal.WinUI.exe','Onyx.OpenTerminal.WinUI.dll') | ForEach-Object {
        @{file=$_;passed=$true;status='Valid';subject=$env:SIGNING_CERTIFICATE_SUBJECT;timestamped=$true}
    } | ConvertTo-Json -AsArray | Set-Content "$smokeDir/application-signatures.json"
    Compress-Archive -Path $candidateDir,$smokeDir -DestinationPath "$fixture/assets/OnyxOpenTerminal-$candidate-$arch-evidence.zip"
}
'test reports' | Set-Content "$fixture/report.trx"
Compress-Archive "$fixture/report.trx" "$fixture/assets/OnyxOpenTerminal-$candidate-unit-tests.zip"
Get-ChildItem "$fixture/assets" | ForEach-Object { "$((Get-FileHash $_.FullName).Hash)  $($_.Name)" } | Set-Content "$fixture/assets/SHA256SUMS.txt"
function global:gh {
    $global:prodCalls += ,@($args)
    $global:LASTEXITCODE = 0
    if ($args[0] -eq 'api') {
        $endpoint = $args[1]
        $value = switch -Wildcard ($endpoint) {
            '*/git/commits/*' { @{tree=@{sha=$(if ($global:prodMode -eq 'changed-source' -and $endpoint.EndsWith($global:prodMain)) {'different'} else {'same'})}}; break }
            '*/commits/*/pulls*' { @(@{merged_at='2026-10-17T00:00:00Z';merge_commit_sha=$global:prodTest;base=@{ref='test'};head=@{ref='develop';sha=$global:prodHead;repo=@{full_name='owner/repo'}}}); break }
            '*/actions/workflows/test.yml/runs*' { @{workflow_runs=@(@{id=42;run_number=42;run_attempt=1;status='completed';conclusion=$(if ($global:prodMode -eq 'failed-run') {'failure'} else {'success'});event='pull_request';path='.github/workflows/test.yml';head_sha=$global:prodHead;head_repository=@{full_name='owner/repo'};created_at='2026-10-17T00:01:00Z';html_url='https://github.com/owner/repo/actions/runs/42'})}; break }
            '*/attempts/1/jobs*' { @{jobs=@(@('validate','package (x64)','package (x86)','Installer smoke test (x64)','Installer smoke test (x86)','Publish GitHub test pre-release') | ForEach-Object { @{name=$_;conclusion=$(if ($global:prodMode -eq 'skipped-job' -and $_ -eq 'validate') {'skipped'} else {'success'}) } })}; break }
            '*/releases/tags/*' { @{draft=$false;prerelease=$true}; break }
            '*/commits/v*' { @{sha=$(if ($global:prodMode -eq 'wrong-tag') {'d'*40} else {$global:prodTest})}; break }
            '*/git/matching-refs/*' { if ($global:prodMode -eq 'existing-tag') { @(@{ref='refs/tags/v0.1.0'}) } else { @() }; break }
            default { throw "Unexpected API: $endpoint" }
        }
        return ConvertTo-Json -InputObject $value -Depth 12 -Compress
    }
    if ($args[1] -eq 'download') {
        $destination = $args[([array]::IndexOf($args,'--dir') + 1)]
        Copy-Item "$global:prodFixture/assets/*" $destination
        if ($global:prodMode -eq 'tampered-asset') { Add-Content "$destination/OnyxOpenTerminal-0.1.0-test.42.1-x64-setup.exe" 'changed' }
        if ($global:prodMode -in @('failed-smoke','wrong-identity','missing-app-signatures')) {
            $archive = "$destination/OnyxOpenTerminal-0.1.0-test.42.1-x64-evidence.zip"
            $zip = [IO.Compression.ZipFile]::Open($archive, [IO.Compression.ZipArchiveMode]::Update)
            try {
                $name = switch ($global:prodMode) {
                    'failed-smoke' { 'smoke-x64/result.json' }
                    'wrong-identity' { 'test-x64/release.json' }
                    'missing-app-signatures' { 'smoke-x64/application-signatures.json' }
                }
                $entry = $zip.GetEntry($name)
                $reader = [IO.StreamReader]::new($entry.Open())
                try { $value = $reader.ReadToEnd() | ConvertFrom-Json } finally { $reader.Dispose() }
                $entry.Delete()
                if ($global:prodMode -ne 'missing-app-signatures') {
                    if ($global:prodMode -eq 'failed-smoke') { $value.status = 'FAIL' } else { $value.commit = 'd' * 40 }
                    $writer = [IO.StreamWriter]::new($zip.CreateEntry($name).Open())
                    try { $writer.Write(($value | ConvertTo-Json)) } finally { $writer.Dispose() }
                }
            } finally { $zip.Dispose() }
            Get-ChildItem $destination | Where-Object Name -ne 'SHA256SUMS.txt' | ForEach-Object {
                "$((Get-FileHash $_.FullName).Hash)  $($_.Name)"
            } | Set-Content "$destination/SHA256SUMS.txt"
        }
    }
    if ($args[1] -eq 'create' -and $global:prodMode -eq 'upload-failure') { $global:LASTEXITCODE = 1 }
}
try {
    $arguments = @{Repository='owner/repo';Commit=$global:prodMain;TestCommit=$global:prodTest;RunUrl='https://github.com/owner/repo/actions/runs/99'}
    & "$fixture/build/promote-prod.ps1" @arguments -OutputDirectory "$fixture/valid"
    $plan = Get-Content "$fixture/valid/promotion.json" -Raw | ConvertFrom-Json
    if ($plan.commit -ne $global:prodMain -or $plan.testCommit -ne $global:prodTest -or $plan.candidateVersion -ne $candidate) { throw 'Lost promotion provenance.' }
    if ((Get-FileHash "$fixture/valid/OnyxOpenTerminal-$candidate-x64-setup.exe").Hash -ne (Get-FileHash "$fixture/assets/OnyxOpenTerminal-$candidate-x64-setup.exe").Hash) { throw 'Promotion changed installer bytes.' }
    $create = @($global:prodCalls | Where-Object { $_[1] -eq 'create' })
    $edit = @($global:prodCalls | Where-Object { $_[1] -eq 'edit' })
    if ($create.Count -ne 1 -or '--draft' -notin $create[0] -or $edit.Count -ne 1 -or '--prerelease=false' -notin $edit[0]) { throw 'Draft-first production publication failed.' }
    Write-Host 'PASS: Equivalent merge trees, matching test run, byte-identical promotion and draft-first publication'
    $cases = @{
        'changed-source'='source differs'; 'failed-run'='No successful'; 'skipped-job'='Required test job';
        'wrong-tag'='validated test commit'; 'tampered-asset'='checksum mismatch'; 'existing-tag'='tag already exists';
        'upload-failure'='draft creation/upload failed'; 'unsigned'='Signature verification failed';
        'missing-subject'='SIGNING_CERTIFICATE_SUBJECT'; 'missing-signing-helper'='signing verification must be merged'
        'failed-smoke'='Passing smoke evidence'; 'wrong-identity'='identity mismatch'; 'missing-app-signatures'='Missing or duplicate evidence'
    }
    foreach ($mode in $cases.Keys) {
        $global:prodMode = $mode; $global:prodCalls = @(); $global:rejectSignature = $mode -eq 'unsigned'
        if ($mode -eq 'missing-subject') { $env:SIGNING_CERTIFICATE_SUBJECT = '' }
        if ($mode -eq 'missing-signing-helper') { Move-Item "$fixture/build/verify-signatures.ps1" "$fixture/build/verify-signatures.hidden" }
        $caught = $false
        try { & "$fixture/build/promote-prod.ps1" @arguments -OutputDirectory "$fixture/$mode" } catch {
            if ($_.Exception.Message -notmatch $cases[$mode]) { throw }
            $caught = $true
        }
        if (!$caught) { throw "Unsafe promotion accepted: $mode" }
        if (@($global:prodCalls | Where-Object { $_[1] -eq 'edit' }).Count) { throw "Published after failed gate: $mode" }
        $env:SIGNING_CERTIFICATE_SUBJECT = 'CN=Fixture publisher'
        if ($mode -eq 'missing-signing-helper') { Move-Item "$fixture/build/verify-signatures.hidden" "$fixture/build/verify-signatures.ps1" }
        Write-Host "PASS: Rejected $mode without publication"
    }
} finally {
    Remove-Item Function:\gh
    $env:SIGNING_CERTIFICATE_SUBJECT = $originalSubject
    Remove-Variable prodFixture,prodMain,prodTest,prodHead,prodMode,prodCalls,rejectSignature -Scope Global -ErrorAction SilentlyContinue
    $global:LASTEXITCODE = 0
}
