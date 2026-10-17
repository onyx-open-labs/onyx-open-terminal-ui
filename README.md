# Onyx Open Terminal UI

[![develop pipeline](https://img.shields.io/github/actions/workflow/status/onyx-open-labs/onyx-open-terminal-ui/develop-build-test.yml?event=pull_request&label=develop)](https://github.com/onyx-open-labs/onyx-open-terminal-ui/actions/workflows/develop-build-test.yml)
[![test pipeline](https://img.shields.io/github/actions/workflow/status/onyx-open-labs/onyx-open-terminal-ui/test.yml?event=pull_request&label=test)](https://github.com/onyx-open-labs/onyx-open-terminal-ui/actions/workflows/test.yml)
[![prod pipeline not configured](https://img.shields.io/badge/prod-not%20configured-lightgrey)](https://github.com/onyx-open-labs/onyx-open-terminal-ui/actions?query=branch%3Amain)

Badges show the latest result of each branch's dedicated integration workflow.
The `test` badge reports automated testing, packaging, installer smoke tests and
pre-release publishing; manual clean-machine and upgrade verification is recorded
separately. Until its first run, a workflow
badge may show no status. A `prod` pipeline (`main` branch) has not yet been configured.

Onyx Open Terminal UI WinUI desktop application.

Test installers are published as [GitHub pre-releases](https://github.com/onyx-open-labs/onyx-open-terminal-ui/releases)
after successful develop-to-test promotion and x64/x86 installer smoke tests.
Each pre-release includes installers, release notes, checksums and test evidence.

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
- `.github/workflows/`: GitHub Actions build and test automation.

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

The Windows runner checks out the event's exact merged commit, installs the SDK
from `global.json`, restores dependencies, builds Release, and runs every test
project in the solution. Each command has its own logged step and a non-zero
exit code fails the job. Test output appears in the logs, and available TRX
results are uploaded as a workflow artifact even when tests fail.

To verify after merging, open the repository's Actions tab and select
"develop". Confirm the checkout, SDK, restore,
build, and test steps pass and download the test-results artifact as needed.

### Security checks

The same merge event starts three independent security jobs. A build or scan
failure does not prevent the other jobs from running:

- NuGet Audit forces a fresh restore and checks direct and transitive packages
  at every severity. Vulnerabilities and audit/restore warnings fail the job.
  A JSON dependency report is uploaded when available.
- Gitleaks CLI scans the history reachable from the updated `develop` branch.
  Detected secrets fail the job; logs and the SARIF report redact secret values.
  The pinned CLI release is verified against its published SHA-256 checksum.
  The free CLI requires no Gitleaks Action organization license.
- CodeQL builds the C# solution on Windows and runs its extended security
  queries. Results appear in GitHub's Security tab and a SARIF artifact. The
  job fails when findings are present or analysis fails. Findings require
  review and may include false positives. CodeQL is free for this public repo;
  private repositories require GitHub Code Security. Use advanced setup for
  this workflow; GitHub's CodeQL default setup must be disabled if enabled.

## Approval and pipeline names

The pipelines are develop, test and prod; prod uses the main Git branch and is
not yet configured. Require an approved PR before merging into each branch.
Branch protection must enforce approvals (including administrators), dismiss stale
approvals and block direct/force pushes. No Actions checks are required before
merging because jobs run after the approved merge. PR creation, updates, approval
alone and manual dispatch do not run pipeline jobs. Closing an unmerged PR may
create a skipped workflow entry; it executes no jobs. See AI.md for the policy.
