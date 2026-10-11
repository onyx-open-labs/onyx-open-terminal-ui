# Onyx Open Terminal UI

Onyx Open Terminal UI WinUI desktop application.

## Prerequisites

- .NET 10 SDK 10.0.301 or a later stable 10.0 SDK (see global.json).
- PowerShell 7 for the optional build scripts.
- Internet access to NuGet.org for initial restore.
- Windows 10 version 1809 or later with WinUI development tooling for the desktop host.

## Build and Test

Run from the repository root:

```powershell
dotnet restore Onyx.OpenTerminal.sln
dotnet build Onyx.OpenTerminal.sln --configuration Release --no-restore
dotnet test Onyx.OpenTerminal.sln --configuration Release --no-build
```

Alternatively, run `pwsh ./build/build.ps1` and `pwsh ./build/test.ps1`.
The solution can be opened in a Visual Studio version supporting .NET 10.

## Structure

- `src/Onyx.OpenTerminal.WinUI/`: unpackaged WinUI desktop application.
- `tests/Onyx.OpenTerminal.WinUI.Tests/`: window configuration tests.
- `docs/`: architecture, decisions, and agent workflows.
- `build/`: restore/build/test automation.
- `deploy/`: reserved deployment documentation.
- `AI.md`: shared AI guidance; `AGENTS.md` points agents to it.
- `agents/`: manually selected specialised-agent briefs.
- `.agents/skills/`: repository skills in SKILL.md format.
- `azure-pipelines.yml`: validation pipeline scaffold; no deployment.

See [structure decisions](docs/decisions/0001-repository-structure.md) and
[AI workflow](docs/ai-workflow.md).

## Contribution Workflow

Use Gitflow. Branch features from `develop` as `feature/OOT-<number>-<description>`.
Merge changes into `develop`, `test`, and `main` only through reviewed pull requests.
Promote validated changes from `develop` to `test`, then from `test` to `main`.
Never push commits directly to these integration branches.

## WinUI desktop application

- Project: src/Onyx.OpenTerminal.WinUI/Onyx.OpenTerminal.WinUI.csproj.
- Requires Windows 10 version 1809 or later, the .NET 10 SDK, and Windows
  development tooling (Visual Studio with the WinUI application development workload).
- The unpackaged application bundles the Windows App SDK runtime; .NET 10
  remains framework-dependent. No MSIX registration is required.
- Build the solution using the commands above (Any CPU maps the WinUI app to x64),
  or select x64/x86 explicitly in Visual Studio.
- WinUI is the debugging startup target. The shared
  Onyx.OpenTerminal.slnLaunch profile starts it with debugging. Use the Unpackaged profile,
  or run dotnet run --project src/Onyx.OpenTerminal.WinUI.
- CI uses a Windows agent because WinUI's XAML compiler requires Windows.

## Automated tests

Run the full suite from the repository root, locally or in a GitHub Actions
Windows runner:

```powershell
pwsh -NoProfile -File ./build/test.ps1
```

This non-interactive command restores and builds the solution in Release, then
runs every test project through VSTest. Restore, build, and test failures return
a non-zero process exit code. Use the same Windows prerequisites listed above;
GitHub Actions must install the SDK required by global.json before running it.
The individual restore/build/test commands above are equivalent when each
failure is checked by the caller. Do not use --no-build without first building.

`tests/Onyx.OpenTerminal.WinUI.Tests/` uses xUnit and the Visual Studio test
adapter with Microsoft.NET.Test.Sdk. It targets the application's Windows .NET
10 framework and defaults to x64 (x86 follows the solution configuration). Its project reference tests the compiled desktop
host's window type; a copied production XAML file verifies the declared title
and centered welcome text. These tests do not activate a window or require an
interactive desktop. They are configuration tests, not UI automation.

## GitHub Actions after integration

`.github/workflows/develop-build-test.yml` handles pull request `closed` events
targeting `develop`. Its build-and-test job runs only when the PR was merged;
closing without merging produces a skipped job and executes no build or tests.
PRs targeting other branches do not start this workflow.

The Windows runner checks out the updated `develop` branch, installs the SDK
from `global.json`, restores dependencies, builds Release, and runs every test
project in the solution. Each command has its own logged step and a non-zero
exit code fails the job. Test output appears in the logs, and available TRX
results are uploaded as a workflow artifact even when tests fail.

To verify after merging, open the repository's Actions tab and select
"Build and test after develop merge". Confirm the checkout, SDK, restore,
build, and test steps pass and download the test-results artifact as needed.
