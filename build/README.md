# Build Automation

Run build.ps1 to restore and build, and test.ps1 to restore, build, and test.
Both scripts locate the solution relative to their own path and propagate
failed command exit codes. Requires PowerShell 7 and the SDK in global.json.
The root Azure pipeline uses the same scripts. Add build/pipelines/ only when
reusable templates are needed.
