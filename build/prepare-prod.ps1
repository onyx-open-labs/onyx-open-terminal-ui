param(
    [Parameter(Mandatory)][string]$InputDirectory,
    [Parameter(Mandatory)][string]$OutputDirectory,
    [Parameter(Mandatory)][ValidatePattern('^\d+\.\d+\.\d+$')][string]$Version,
    [Parameter(Mandatory)][string]$CandidateVersion,
    [Parameter(Mandatory)][string]$Commit,
    [Parameter(Mandatory)][string]$TestCommit,
    [Parameter(Mandatory)][string]$TestRunUrl,
    [Parameter(Mandatory)][string]$RunUrl,
    [Parameter(Mandatory)][string]$Repository
)
$ErrorActionPreference = 'Stop'
$inputRoot = (Resolve-Path -LiteralPath $InputDirectory).Path
$output = [IO.Path]::GetFullPath($OutputDirectory)
if ($CandidateVersion -notmatch ('^' + [regex]::Escape($Version) + '-test\.\d+\.\d+$')) { throw 'Candidate base version must match production.' }
$expected = @('x64','x86') | ForEach-Object {
    "OnyxOpenTerminal-$CandidateVersion-$_-setup.exe"
    "OnyxOpenTerminal-$CandidateVersion-$_-evidence.zip"
}
$expected += "OnyxOpenTerminal-$CandidateVersion-unit-tests.zip"
$lines = @(Get-Content (Join-Path $inputRoot 'SHA256SUMS.txt'))
$hashes = @{}
foreach ($line in $lines) {
    if ($line -notmatch '^([a-fA-F0-9]{64})  ([A-Za-z0-9_.-]+)$') { throw 'Invalid checksum manifest entry.' }
    $hash = $Matches[1]; $name = $Matches[2]
    if ($hashes.ContainsKey($name) -or $name -notin $expected) { throw 'Unexpected or duplicate checksum entry.' }
    $hashes[$name] = $hash
}
if ($hashes.Count -ne $expected.Count) { throw 'Incomplete checksum manifest.' }
foreach ($name in $expected) {
    if ((Get-FileHash -LiteralPath (Join-Path $inputRoot $name) -Algorithm SHA256).Hash -ne $hashes[$name]) { throw "Asset checksum mismatch: $name" }
}
# Read only named ZIP entries; never extract archive-controlled paths.
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Read-ZipJson($Zip, [string]$Name) {
    $entries = @($Zip.Entries | Where-Object { $_.FullName.Replace('\','/') -eq $Name })
    if ($entries.Count -ne 1) { throw "Missing or duplicate evidence entry: $Name" }
    $reader = [IO.StreamReader]::new($entries[0].Open())
    try { return $reader.ReadToEnd() | ConvertFrom-Json } finally { $reader.Dispose() }
}
$subject = $env:SIGNING_CERTIFICATE_SUBJECT
if ([string]::IsNullOrWhiteSpace($subject)) { throw 'OOT-11: configure SIGNING_CERTIFICATE_SUBJECT before production publication.' }
$verifier = Join-Path $PSScriptRoot 'verify-signatures.ps1'
if (!(Test-Path -LiteralPath $verifier)) { throw 'OOT-11 signing verification must be merged before production publication.' }
foreach ($architecture in @('x64','x86')) {
    $zip = [IO.Compression.ZipFile]::OpenRead((Join-Path $inputRoot "OnyxOpenTerminal-$CandidateVersion-$architecture-evidence.zip"))
    try {
        $identity = Read-ZipJson $zip "test-$architecture/release.json"
        $smoke = Read-ZipJson $zip "smoke-$architecture/result.json"
        if ($identity.version -ne $CandidateVersion -or $identity.commit -ne $TestCommit -or $identity.architecture -ne $architecture -or $identity.workflow -ne $TestRunUrl -or
            $identity.product -ne 'Onyx Open Terminal' -or $identity.organisation -ne 'Onyx Open Labs' -or $identity.licence -ne 'MIT') { throw "Candidate identity mismatch: $architecture" }
        if ($smoke.status -ne 'PASS' -or $smoke.version -ne $CandidateVersion -or $smoke.commit -ne $TestCommit -or $smoke.architecture -ne $architecture) { throw "Passing smoke evidence required: $architecture" }
        $signatures = @(Read-ZipJson $zip "smoke-$architecture/application-signatures.json")
        foreach ($file in @('Onyx.OpenTerminal.WinUI.exe','Onyx.OpenTerminal.WinUI.dll')) {
            $record = @($signatures | Where-Object file -eq $file)
            if ($record.Count -ne 1 -or $record[0].passed -ne $true -or $record[0].status -ne 'Valid' -or $record[0].subject -ne $subject -or $record[0].timestamped -ne $true) { throw "Trusted application signing evidence required: $architecture/$file" }
        }
        $installerName = "OnyxOpenTerminal-$CandidateVersion-$architecture-setup.exe"
        $installerEvidence = @(Read-ZipJson $zip "smoke-$architecture/installer-signatures.json")
        if ($installerEvidence.Count -ne 1 -or $installerEvidence[0].sha256 -ne $hashes[$installerName]) { throw 'Installer signature evidence does not match promoted bytes.' }
    } finally { $zip.Dispose() }
    & $verifier -Path (Join-Path $inputRoot $installerName) -EvidencePath (Join-Path $output "installer-signatures-$architecture.json")
}
New-Item -ItemType Directory -Force $output | Out-Null
$assets = @($expected) + 'SHA256SUMS.txt'
foreach ($name in $assets) { Copy-Item -LiteralPath (Join-Path $inputRoot $name) -Destination (Join-Path $output $name) }
$assets += @('installer-signatures-x64.json','installer-signatures-x86.json','promotion.json','release-notes.md')
@{version=$Version; candidateVersion=$CandidateVersion; commit=$Commit; testCommit=$TestCommit; repository=$Repository;
  testWorkflow=$TestRunUrl; productionWorkflow=$RunUrl; assets=$assets;
  reusedChecks=@('solution build and unit tests','x64/x86 installer smoke tests','application signing verification');
  productionChecks=@('identical source trees','successful matching test run','release identity and checksums','trusted timestamped installer signatures')} |
    ConvertTo-Json -Depth 5 | Set-Content (Join-Path $output 'promotion.json')
@"
Onyx Open Terminal $Version

Production source: $Commit
Validated test source: $TestCommit
Test evidence: $TestRunUrl
Production promotion: $RunUrl

These are the exact signed installers validated in test. Their filenames and
installed application version remain $CandidateVersion to preserve tested bytes.
The production release/tag is v$Version; no binaries were rebuilt or renamed.
Solution tests and installer smoke tests are reused from the successful test run.
Production verified matching source trees, candidate identity, asset checksums
and trusted timestamped installer signatures. Application signature evidence is
retained from test. Manual clean-machine/upgrade checks are not claimed by this run;
consult the attached evidence and tester records for their status.
"@ | Set-Content (Join-Path $output 'release-notes.md')
