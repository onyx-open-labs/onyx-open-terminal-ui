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
- WinUI is the sole solution project and the debugging startup target. The shared
  Onyx.OpenTerminal.slnLaunch profile starts it with debugging. Use the Unpackaged profile,
  or run dotnet run --project src/Onyx.OpenTerminal.WinUI.
- CI uses a Windows agent because WinUI's XAML compiler requires Windows.

The unused UI library and its scaffold test project have been removed. There are
currently no automated test projects; validation consists of build and launch checks.
