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
