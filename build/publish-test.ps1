param(
    [Parameter(Mandatory)][string]$ArtifactDirectory,
    [Parameter(Mandatory)][string]$OutputDirectory,
    [Parameter(Mandatory)][ValidatePattern('^[a-f0-9]{40}$')][string]$Commit,
    [Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$')][string]$Repository,
    [Parameter(Mandatory)][string]$RunUrl,
    [switch]$PrepareOnly
)
$ErrorActionPreference = 'Stop'
$inputRoot = (Resolve-Path -LiteralPath $ArtifactDirectory).Path
$output = [IO.Path]::GetFullPath($OutputDirectory)
if (Test-Path -LiteralPath $output) {
    if (@(Get-ChildItem -LiteralPath $output -Force).Count) { throw 'Release output directory must be empty.' }
}
$candidates = @{}
$version = $null
foreach ($architecture in @('x64', 'x86')) {
    $directory = Join-Path $inputRoot "test-$architecture"
    $metadata = Get-Content -LiteralPath (Join-Path $directory 'release.json') -Raw | ConvertFrom-Json
    if ($metadata.version -notmatch '^\d+\.\d+\.\d+-test\.\d+\.\d+$') { throw "Invalid candidate version for $architecture." }
    if (!$version) { $version = $metadata.version }
    if ($metadata.version -ne $version -or $metadata.commit -ne $Commit -or $metadata.architecture -ne $architecture -or $metadata.workflow -ne $RunUrl) {
        throw "Candidate identity mismatch for $architecture."
    }
    if ($metadata.product -ne 'Onyx Open Terminal' -or $metadata.organisation -ne 'Onyx Open Labs' -or $metadata.licence -ne 'MIT') {
        throw "Candidate product metadata mismatch for $architecture."
    }
    $smokeDirectory = Join-Path $inputRoot "smoke-$architecture"
    $result = Get-Content -LiteralPath (Join-Path $smokeDirectory 'result.json') -Raw | ConvertFrom-Json
    if ($result.status -ne 'PASS' -or $result.version -ne $version -or $result.architecture -ne $architecture -or $result.commit -ne $Commit) {
        throw "Passing smoke evidence for this candidate is required: $architecture."
    }
    $installers = @(Get-ChildItem -LiteralPath $directory -Filter '*-setup.exe')
    if ($installers.Count -ne 1 -or $installers[0].Name -ne "OnyxOpenTerminal-$version-$architecture-setup.exe") {
        throw "Expected exactly one correctly named installer for $architecture."
    }
    foreach ($file in @('TESTING.md', 'KNOWN-ISSUES.md', 'CHANGES.txt', 'LICENSE', 'test-results.md')) {
        if (!(Test-Path -LiteralPath (Join-Path $directory $file))) { throw "Missing tester handoff file: $architecture/$file" }
    }
    $candidates[$architecture] = @{directory=$directory; smoke=$smokeDirectory; installer=$installers[0].FullName}
}
$testDirectory = Join-Path $inputRoot 'unit-tests'
if (!(Test-Path -LiteralPath $testDirectory) -or !(Get-ChildItem -LiteralPath $testDirectory -Filter '*.trx')) {
    throw 'Automated solution test reports are required.'
}
New-Item -ItemType Directory -Force -Path $output | Out-Null
$assets = [Collections.Generic.List[string]]::new()
foreach ($architecture in @('x64', 'x86')) {
    $candidate = $candidates[$architecture]
    $installer = Join-Path $output ([IO.Path]::GetFileName($candidate.installer))
    Copy-Item -LiteralPath $candidate.installer -Destination $installer
    $assets.Add($installer)
    # Preserve handoff documents and smoke logs without merging architecture files.
    $bundle = Join-Path $output "OnyxOpenTerminal-$version-$architecture-evidence.zip"
    Compress-Archive -Path $candidate.directory, $candidate.smoke -DestinationPath $bundle
    $assets.Add($bundle)
}
$testBundle = Join-Path $output "OnyxOpenTerminal-$version-unit-tests.zip"
Compress-Archive -Path $testDirectory -DestinationPath $testBundle
$assets.Add($testBundle)
$checksums = Join-Path $output 'SHA256SUMS.txt'
$assets | ForEach-Object {
    $hash = Get-FileHash -LiteralPath $_ -Algorithm SHA256
    "$($hash.Hash.ToLowerInvariant())  $([IO.Path]::GetFileName($_))"
} | Set-Content -LiteralPath $checksums -Encoding utf8
$assets.Add($checksums)
$changes = Get-Content -LiteralPath (Join-Path $candidates.x64.directory 'CHANGES.txt') -Raw
$knownIssues = Get-Content -LiteralPath (Join-Path $candidates.x64.directory 'KNOWN-ISSUES.md') -Raw
$notes = @"
Onyx Open Terminal $version - test pre-release

Organisation: Onyx Open Labs. Licence: MIT.
Source commit: $Commit
Build and test evidence: $RunUrl

## Downloads

Choose the x64 or x86 setup executable. Installation is per-user and includes
the .NET and Windows App SDK runtimes. Installers and the installed application require trusted, timestamped signatures.
The matching evidence ZIP contains release identity, testing instructions,
known issues, the pending manual verification record, and installer smoke logs.
SHA256SUMS.txt contains checksums for the installers and evidence archives.

## Verification

Solution build/tests and x64/x86 installer smoke tests passed before publication.
Smoke checks cover installation, metadata, shortcut target, a visible responsive
window with the expected version, and uninstall.
Manual clean-machine and previous-test upgrade/data-preservation checks remain
pending. This pre-release is available for test testing; it is not a production release.

## Changes since the previous test commit

$changes

## Known issues

$knownIssues
"@
$notesPath = Join-Path $output 'release-notes.md'
$notes | Set-Content -LiteralPath $notesPath -Encoding utf8
$tag = "v$version"
@{tag=$tag; commit=$Commit; version=$version; repository=$Repository; prerelease=$true; assets=@($assets.ToArray())} |
    ConvertTo-Json -Depth 4 | Set-Content (Join-Path $output 'release-plan.json')
Write-Host "Prepared $tag from $Commit with $($assets.Count) assets; both architecture smoke results passed."
if ($PrepareOnly) { return }
if (!(Get-Command gh -ErrorAction SilentlyContinue)) { throw 'GitHub CLI is required to publish a test pre-release.' }
$referencesJson = & gh api "repos/$Repository/git/matching-refs/tags/$tag"
if ($LASTEXITCODE) { throw 'Could not verify that the release tag is available.' }
$references = ($referencesJson -join "`n") | ConvertFrom-Json
if (@($references | Where-Object { $_.ref -eq "refs/tags/$tag" }).Count) {
    throw "Release tag already exists: $tag. Rerun the entire workflow to produce a new candidate version."
}
# gh stages a draft, uploads all assets, then publishes. A failed upload must not
# expose a partially populated public release. Never overwrite an existing tag.
$assetPaths = $assets.ToArray()
& gh release create $tag @assetPaths --repo $Repository --target $Commit --title "Onyx Open Terminal $version" --notes-file $notesPath --prerelease --latest=false
if ($LASTEXITCODE) { throw "GitHub pre-release publication failed: $LASTEXITCODE" }
Write-Host "Published https://github.com/$Repository/releases/tag/$tag"

