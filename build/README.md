# Build Automation

Run build.ps1 to restore and build, and test.ps1 to restore, build, and test.
Both scripts locate the solution relative to their own path and propagate
failed command exit codes. Requires PowerShell 7 and the SDK in global.json.
GitHub Actions uses equivalent restore, build, and test commands in
`.github/workflows/develop-build-test.yml`, with separate logs for each stage.

Solution validation now requires Windows with WinUI development tooling.
The desktop host defaults to x64; use the solution x86 configuration for x86 builds.

Full-suite command from the repository root (including GitHub Actions):
`pwsh -NoProfile -File ./build/test.ps1`.
It restores, builds Release, runs all solution tests, and returns the first
failing command's non-zero exit code. No interactive steps are required.
Tests use xUnit/VSTest and run as x64 on Windows; see the root README for setup.

`test-installer.ps1` tests an actual generated installer: silent install,
required XAML resources and metadata, shortcut target, visible responsive versioned
window, and uninstall. It saves result.json and diagnostic logs and returns a
failure when any check fails. It refuses to modify an existing installation;
run on a fresh Windows runner/user. See deploy/BETA-TESTING.md for the workflow
evidence and the remaining manual clean-machine/upgrade checks.
