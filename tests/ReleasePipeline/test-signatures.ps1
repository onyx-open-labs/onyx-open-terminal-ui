$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot)
$directory = Join-Path ([IO.Path]::GetTempPath()) ("onyx-signatures-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $directory | Out-Null
$file = Join-Path $directory 'fixture.exe'
'evidence fixture' | Set-Content $file
$evidence = Join-Path $directory 'signatures.json'
$global:OnyxSignatureStatus = 'Valid'
$global:OnyxSignatureSubject = 'CN=Expected'
$global:OnyxSignatureTimestamp = [pscustomobject]@{Subject='CN=TSA'}
# Mock only the Windows API boundary; exercise the real verifier and evidence writer.
function Get-AuthenticodeSignature {
    param($LiteralPath)
    [pscustomobject]@{
        Status=$global:OnyxSignatureStatus
        SignerCertificate=$(if ($global:OnyxSignatureStatus -eq 'NotSigned') {$null} else {[pscustomobject]@{Subject=$global:OnyxSignatureSubject; Thumbprint='fixture'}})
        TimeStamperCertificate=$global:OnyxSignatureTimestamp
    }
}
$verifier = Join-Path $root 'build/verify-signatures.ps1'
function Check-Rejected([string]$Name) {
    $rejected = $false
    try { & $verifier -Path $file -EvidencePath $evidence -ExpectedSubject 'CN=Expected' } catch { $rejected = $true }
    if (!$rejected) { throw "Expected rejection: $Name" }
    if (@(Get-Content $evidence -Raw | ConvertFrom-Json)[0].passed) { throw "Evidence incorrectly passed: $Name" }
}
try {
    & $verifier -Path $file -EvidencePath $evidence -ExpectedSubject 'CN=Expected'
    if (!@(Get-Content $evidence -Raw | ConvertFrom-Json)[0].passed) { throw 'Valid signature did not pass.' }
    $global:OnyxSignatureStatus='NotSigned'; Check-Rejected 'unsigned file'
    $global:OnyxSignatureStatus='HashMismatch'; Check-Rejected 'tampered file'
    $global:OnyxSignatureStatus='NotTrusted'; Check-Rejected 'untrusted certificate'
    $global:OnyxSignatureStatus='Valid'; $global:OnyxSignatureSubject='CN=Unexpected'; Check-Rejected 'wrong publisher'
    $global:OnyxSignatureSubject='CN=Expected'; $global:OnyxSignatureTimestamp=$null; Check-Rejected 'missing timestamp'
    $rejected=$false
    try { & $verifier -Path $file -EvidencePath $evidence -ExpectedSubject '' } catch { $rejected=$true }
    if (!$rejected) { throw 'Missing configuration accepted.' }
    Write-Host 'PASS: 7 signature trust and failure-guard cases.'
} finally {
    # Only remove explicitly named files created by this test.
    Remove-Item -LiteralPath $file -Force
    if (Test-Path -LiteralPath $evidence) { Remove-Item -LiteralPath $evidence -Force }
    Remove-Item -LiteralPath $directory
}

