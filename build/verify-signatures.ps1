param(
    [Parameter(Mandatory)][string[]]$Path,
    [Parameter(Mandatory)][string]$EvidencePath,
    [string]$ExpectedSubject = $env:SIGNING_CERTIFICATE_SUBJECT
)
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($ExpectedSubject)) { throw 'Configure SIGNING_CERTIFICATE_SUBJECT from the approved signing certificate.' }
$records = @()
$failed = $false
foreach ($file in $Path) {
    $resolved = (Resolve-Path -LiteralPath $file).Path
    $signature = Get-AuthenticodeSignature -LiteralPath $resolved
    $valid = $signature.Status -eq 'Valid' -and $signature.SignerCertificate.Subject -eq $ExpectedSubject -and $null -ne $signature.TimeStamperCertificate
    if (!$valid) { $failed = $true }
    $records += @{
        file = [IO.Path]::GetFileName($resolved)
        sha256 = (Get-FileHash -LiteralPath $resolved -Algorithm SHA256).Hash
        status = $signature.Status.ToString()
        subject = $signature.SignerCertificate.Subject
        thumbprint = $signature.SignerCertificate.Thumbprint
        timestamped = $null -ne $signature.TimeStamperCertificate
        passed = $valid
    }
}
$parent = Split-Path ([IO.Path]::GetFullPath($EvidencePath))
New-Item -ItemType Directory -Path $parent -Force | Out-Null
ConvertTo-Json -InputObject @($records) -Depth 4 | Set-Content -LiteralPath $EvidencePath -Encoding utf8
if ($failed) { throw 'Signature verification failed: require Windows trust, the configured publisher subject and a timestamp. See signature evidence.' }

