param([Parameter(Mandatory)][string]$Destination)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force $Destination | Out-Null
$download = Join-Path $Destination 'innosetup-6.7.3.exe'
Invoke-WebRequest 'https://github.com/jrsoftware/issrc/releases/download/is-6_7_3/innosetup-6.7.3.exe' -OutFile $download
$signature = Get-AuthenticodeSignature $download
if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'Pyrsys B.V.') {
    throw 'Installer compiler signature verification failed.'
}
$process = Start-Process $download -ArgumentList @('/CURRENTUSER','/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART',"/DIR=`"$Destination`"") -WindowStyle Hidden -Wait -PassThru
if ($process.ExitCode -ne 0) { throw "Compiler installation failed: $($process.ExitCode)" }
if (!(Test-Path (Join-Path $Destination 'ISCC.exe'))) { throw 'Compiler not found after installation.' }
