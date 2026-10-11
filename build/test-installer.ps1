param(
    [Parameter(Mandatory)][string]$InstallerPath,
    [Parameter(Mandatory)][string]$ReleaseMetadataPath,
    [Parameter(Mandatory)][string]$EvidenceDirectory,
    # Override only for locally compiled installers with an isolated test AppId.
    [string]$RegistrationId
)
$ErrorActionPreference = 'Stop'
$installer = (Resolve-Path -LiteralPath $InstallerPath).Path
$metadata = Get-Content -LiteralPath $ReleaseMetadataPath -Raw | ConvertFrom-Json
if ($metadata.architecture -notin @('x64', 'x86')) { throw 'Unsupported installer architecture.' }
if (!$RegistrationId) { $RegistrationId = "OnyxOpenTerminal-$($metadata.architecture)" }
if ($RegistrationId -notmatch '^[A-Za-z0-9-]+$') { throw 'Invalid registration ID.' }
$evidence = [IO.Path]::GetFullPath($EvidenceDirectory)
New-Item -ItemType Directory -Force -Path $evidence | Out-Null
$testId = [Guid]::NewGuid().ToString('N')
$installDirectory = Join-Path ([IO.Path]::GetTempPath()) "OnyxInstallerSmoke-$testId"
$groupName = "Onyx Installer Smoke $testId"
$shortcutDirectory = Join-Path ([Environment]::GetFolderPath('Programs')) $groupName
$registrationPaths = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\${RegistrationId}_is1",
    "HKCU:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\${RegistrationId}_is1",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\${RegistrationId}_is1",
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\${RegistrationId}_is1"
)
$started = Get-Date
$checks = [Collections.Generic.List[string]]::new()
$failure = $null
$app = $null
$installationAttempted = $false
Start-Transcript -Path (Join-Path $evidence 'smoke.log') -Force | Out-Null

function Invoke-Setup([string]$Path, [string[]]$Arguments, [int]$TimeoutSeconds = 180) {
    $process = Start-Process -FilePath $Path -ArgumentList $Arguments -PassThru -WindowStyle Hidden
    if (!$process.WaitForExit($TimeoutSeconds * 1000)) {
        $process.Kill($true)
        throw "Installer process timed out: $Path"
    }
    if ($process.ExitCode -ne 0) { throw "Installer process failed with exit code $($process.ExitCode): $Path" }
}

function Record-Pass([string]$Check) {
    $checks.Add($Check)
    Write-Host "PASS: $Check"
}

try {
    # Refuse to alter an existing installation, including on a developer's machine.
    foreach ($path in $registrationPaths) {
        if (Test-Path -LiteralPath $path) { throw "Existing installation found at $path. Use a fresh runner/user for a clean-install smoke test." }
    }
    Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class InstallerSmokeWindow {
    private delegate bool EnumWindowsCallback(IntPtr window, IntPtr parameter);
    [DllImport("user32.dll")] private static extern bool EnumWindows(EnumWindowsCallback callback, IntPtr parameter);
    [DllImport("user32.dll")] private static extern uint GetWindowThreadProcessId(IntPtr window, out uint processId);
    [DllImport("user32.dll")] private static extern bool IsWindowVisible(IntPtr window);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] private static extern int GetWindowText(IntPtr window, StringBuilder text, int size);
    [DllImport("user32.dll", SetLastError = true)] private static extern IntPtr SendMessageTimeout(IntPtr window, uint message, IntPtr wParam, IntPtr lParam, uint flags, uint timeout, out IntPtr result);
    public static bool IsReady(int processId, string expectedTitle) {
        bool ready = false;
        EnumWindows((window, parameter) => {
            uint owner;
            GetWindowThreadProcessId(window, out owner);
            if (owner != processId || !IsWindowVisible(window)) return true;
            var title = new StringBuilder(512);
            GetWindowText(window, title, title.Capacity);
            IntPtr result;
            if (title.ToString() == expectedTitle && SendMessageTimeout(window, 0, IntPtr.Zero, IntPtr.Zero, 2, 1000, out result) != IntPtr.Zero) ready = true;
            return !ready;
        }, IntPtr.Zero);
        return ready;
    }
}
'@
    Write-Host "Installing $($metadata.architecture) candidate $($metadata.version)"
    $installationAttempted = $true
    Invoke-Setup $installer @('/CURRENTUSER', '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/SP-',
        "/DIR=`"$installDirectory`"", "/GROUP=`"$groupName`"", "/LOG=`"$(Join-Path $evidence 'install.log')`"")
    $executable = Join-Path $installDirectory 'Onyx.OpenTerminal.WinUI.exe'
    foreach ($file in @('Onyx.OpenTerminal.WinUI.exe', 'Onyx.OpenTerminal.WinUI.pri', 'App.xbf', 'MainWindow.xbf', 'LICENSE', 'release.json')) {
        if (!(Test-Path -LiteralPath (Join-Path $installDirectory $file))) { throw "Installed file missing: $file" }
    }
    Record-Pass 'Silent installation and required application resources'
    $installedMetadata = Get-Content (Join-Path $installDirectory 'release.json') -Raw | ConvertFrom-Json
    foreach ($field in @('version', 'numericVersion', 'architecture', 'commit', 'organisation', 'licence')) {
        if ($installedMetadata.$field -ne $metadata.$field) { throw "Installed release metadata mismatch: $field" }
    }
    $registration = @($registrationPaths | Where-Object { Test-Path -LiteralPath $_ })
    if ($registration.Count -ne 1) { throw 'Expected exactly one Installed Apps registration.' }
    $entry = Get-ItemProperty -LiteralPath $registration[0]
    if ($entry.DisplayVersion -ne $metadata.version -or $entry.Publisher -ne 'Onyx Open Labs') { throw 'Installed Apps version or publisher mismatch.' }
    if ((Get-Item -LiteralPath $executable).VersionInfo.FileVersion -ne $metadata.numericVersion) { throw 'Installed executable file version mismatch.' }
    if ((Get-Content (Join-Path $installDirectory 'LICENSE') -Raw) -notmatch 'MIT License') { throw 'Installed MIT licence text missing.' }
    Record-Pass 'Installed version, publisher, licence and release identity'
    $shortcut = Join-Path $shortcutDirectory 'Onyx Open Terminal.lnk'
    if (!(Test-Path -LiteralPath $shortcut)) { throw 'Start menu shortcut missing.' }
    $shell = New-Object -ComObject WScript.Shell
    if ($shell.CreateShortcut($shortcut).TargetPath -ne $executable) { throw 'Start menu shortcut target mismatch.' }
    Record-Pass 'Start menu shortcut points to installed executable'

    # Use the installed executable and a different working directory, like a shortcut launch.
    $app = Start-Process -FilePath $executable -WorkingDirectory $evidence -PassThru
    $expectedTitle = "Onyx Open Terminal $($metadata.version)"
    $deadline = (Get-Date).AddSeconds(60)
    $readySince = $null
    while ((Get-Date) -lt $deadline) {
        $app.Refresh()
        if ($app.HasExited) { throw "Installed app exited before completing smoke test: $($app.ExitCode)" }
        if ([InstallerSmokeWindow]::IsReady($app.Id, $expectedTitle)) {
            if (!$readySince) { $readySince = Get-Date }
            if (((Get-Date) - $readySince).TotalSeconds -ge 5) { break }
        } else { $readySince = $null }
        Start-Sleep -Milliseconds 500
    }
    if (!$readySince -or ((Get-Date) - $readySince).TotalSeconds -lt 5) { throw "No visible, responsive window with title '$expectedTitle' within 60 seconds." }
    Record-Pass "Installed app opens a visible, responsive window with version $($metadata.version) and stays open"
} catch {
    $failure = $_.ToString()
    Write-Host "FAIL: $failure"
} finally {
    if ($app -and !$app.HasExited) {
        $null = $app.CloseMainWindow()
        if (!$app.WaitForExit(5000)) { $app.Kill($true); $app.WaitForExit() }
    }
    if ($installationAttempted) {
        try {
            $uninstaller = Join-Path $installDirectory 'unins000.exe'
            if (!(Test-Path -LiteralPath $uninstaller)) { throw 'Installed uninstaller missing.' }
            Invoke-Setup $uninstaller @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', "/LOG=`"$(Join-Path $evidence 'uninstall.log')`"")
            if (Test-Path -LiteralPath (Join-Path $installDirectory 'Onyx.OpenTerminal.WinUI.exe')) { throw 'Application executable remains after uninstall.' }
            if (Test-Path -LiteralPath $shortcutDirectory) { throw 'Start menu shortcut directory remains after uninstall.' }
            foreach ($path in $registrationPaths) { if (Test-Path -LiteralPath $path) { throw "Installed Apps registration remains after uninstall: $path" } }
            Record-Pass 'Silent uninstall removes executable, shortcut and Installed Apps registration'
        } catch {
            $failure = "$failure`nUninstall check: $($_.ToString())".Trim()
            Write-Host "FAIL: $($_.ToString())"
        }
    }
    try {
        Get-WinEvent -FilterHashtable @{LogName='Application'; StartTime=$started} -ErrorAction Stop |
            Where-Object { $_.Message -match 'Onyx.OpenTerminal.WinUI|Microsoft.UI.Xaml' } |
            Select-Object TimeCreated, Id, ProviderName, Message |
            ConvertTo-Json -Depth 4 | Set-Content (Join-Path $evidence 'application-events.json')
    } catch { $_.ToString() | Set-Content (Join-Path $evidence 'event-log-read.txt') }
    @{ status=$(if ($failure) {'FAIL'} else {'PASS'}); version=$metadata.version; architecture=$metadata.architecture;
       commit=$metadata.commit; started=$started.ToUniversalTime().ToString('o'); checks=@($checks.ToArray()); failure=$failure;
       windows=[Environment]::OSVersion.VersionString } | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $evidence 'result.json')
    Stop-Transcript | Out-Null
}
if ($failure) { throw $failure }
