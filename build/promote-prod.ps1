param(
    [Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$')][string]$Repository,
    [Parameter(Mandatory)][ValidatePattern('^[a-f0-9]{40}$')][string]$Commit,
    [Parameter(Mandatory)][ValidatePattern('^[a-f0-9]{40}$')][string]$TestCommit,
    [Parameter(Mandatory)][string]$RunUrl,
    [Parameter(Mandatory)][string]$OutputDirectory,
    [switch]$PrepareOnly
)
$ErrorActionPreference = 'Stop'
function Read-GitHub([string]$Endpoint) {
    $json = & gh api $Endpoint
    if ($LASTEXITCODE) { throw "GitHub lookup failed: $Endpoint" }
    return ($json -join "`n") | ConvertFrom-Json
}
function Read-Pages([string]$Endpoint, [string]$Property) {
    $items = @()
    for ($page = 1; ; $page++) {
        $separator = if ($Endpoint.Contains('?')) { '&' } else { '?' }
        $response = Read-GitHub "$Endpoint${separator}per_page=100&page=$page"
        $batch = if ($Property) { @($response.$Property) } else { @($response) }
        $items += $batch
        if ($batch.Count -lt 100) { break }
    }
    return $items
}
$output = [IO.Path]::GetFullPath($OutputDirectory)
if ((Test-Path -LiteralPath $output) -and @(Get-ChildItem -LiteralPath $output -Force).Count) {
    throw 'Production output directory must be empty; never reuse stale release inputs.'
}
New-Item -ItemType Directory -Force $output | Out-Null
$main = Read-GitHub "repos/$Repository/git/commits/$Commit"
$test = Read-GitHub "repos/$Repository/git/commits/$TestCommit"
if (!$main.tree.sha -or $main.tree.sha -ne $test.tree.sha) {
    throw 'Production source differs from test. Promote the changed source through develop/test validation first.'
}
# Closed-PR runs report the PR head SHA, while checkout tests the merge SHA.
# Resolve the approved develop-to-test PR rather than assuming run.head_sha is tested.
$prs = @(Read-Pages "repos/$Repository/commits/$TestCommit/pulls" '' | Where-Object {
    $_.merged_at -and $_.merge_commit_sha -eq $TestCommit -and $_.base.ref -eq 'test' -and
    $_.head.ref -eq 'develop' -and $_.head.repo.full_name -eq $Repository
})
if ($prs.Count -ne 1) { throw 'Expected one merged develop-to-test PR for the promoted test commit.' }
$head = $prs[0].head.sha
$runs = @(Read-Pages "repos/$Repository/actions/workflows/test.yml/runs?event=pull_request&head_sha=$head" 'workflow_runs' |
    Where-Object { $_.status -eq 'completed' -and $_.conclusion -eq 'success' -and $_.event -eq 'pull_request' -and
        $_.path -eq '.github/workflows/test.yml' -and $_.head_sha -eq $head -and $_.head_repository.full_name -eq $Repository -and
        [datetime]$_.created_at -ge [datetime]$prs[0].merged_at } |
    Sort-Object id -Descending)
if (!$runs.Count) { throw 'No successful matching test workflow. Complete test promotion before production.' }
$run = $runs[0]
$jobs = @(Read-Pages "repos/$Repository/actions/runs/$($run.id)/attempts/$($run.run_attempt)/jobs" 'jobs')
foreach ($name in @('validate','package (x64)','package (x86)','Installer smoke test (x64)','Installer smoke test (x86)','Publish GitHub test pre-release')) {
    $job = @($jobs | Where-Object name -eq $name)
    if ($job.Count -ne 1 -or $job[0].conclusion -ne 'success') { throw "Required test job did not pass: $name" }
}
$version = (Get-Content (Join-Path (Split-Path $PSScriptRoot) 'deploy/version.json') -Raw | ConvertFrom-Json).version
if ($version -notmatch '^\d+\.\d+\.\d+$') { throw 'Expected a three-part production version.' }
$candidateVersion = "$version-test.$($run.run_number).$($run.run_attempt)"
$candidateTag = "v$candidateVersion"
$release = Read-GitHub "repos/$Repository/releases/tags/$candidateTag"
$tagCommit = Read-GitHub "repos/$Repository/commits/$candidateTag"
if ($release.draft -or !$release.prerelease -or $tagCommit.sha -ne $TestCommit) {
    throw 'Test release is not a published pre-release of the validated test commit.'
}
$download = Join-Path $output 'validated-test'
New-Item -ItemType Directory $download | Out-Null
& gh release download $candidateTag --repo $Repository --dir $download
if ($LASTEXITCODE) { throw 'Could not download validated test release assets.' }
& (Join-Path $PSScriptRoot 'prepare-prod.ps1') -InputDirectory $download -OutputDirectory $output -Version $version -CandidateVersion $candidateVersion -Commit $Commit -TestCommit $TestCommit -TestRunUrl $run.html_url -RunUrl $RunUrl -Repository $Repository
if ($PrepareOnly) { return }
$tag = "v$version"
$refs = @(Read-GitHub "repos/$Repository/git/matching-refs/tags/$tag")
if (@($refs | Where-Object ref -eq "refs/tags/$tag").Count) { throw "Production tag already exists: $tag. Never overwrite a released version." }
$plan = Get-Content (Join-Path $output 'promotion.json') -Raw | ConvertFrom-Json
$assets = @($plan.assets | ForEach-Object { Join-Path $output $_ })
# Stage a draft with all assets; publish only after every upload succeeds.
& gh release create $tag @assets --repo $Repository --target $Commit --title "Onyx Open Terminal $version" --notes-file (Join-Path $output 'release-notes.md') --draft --latest=false
if ($LASTEXITCODE) { throw 'Production draft creation/upload failed. Publication was not requested.' }
& gh release edit $tag --repo $Repository --draft=false --prerelease=false --latest
if ($LASTEXITCODE) { throw 'Production publication failed; inspect the draft before retrying.' }
Write-Host "Published https://github.com/$Repository/releases/tag/$tag"
