# Onyx Open Terminal UI

Initial .NET solution scaffold for Onyx Open Terminal UI.

## Prerequisites

- .NET 10 SDK 10.0.301 or a later stable 10.0 SDK (see global.json).
- PowerShell 7 for the optional build scripts.
- Internet access to NuGet.org for initial restore.

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

- `src/Onyx.OpenTerminal.UI/`: framework-neutral UI library scaffold.
- `tests/Onyx.OpenTerminal.UI.Tests/`: matching xUnit tests.
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
