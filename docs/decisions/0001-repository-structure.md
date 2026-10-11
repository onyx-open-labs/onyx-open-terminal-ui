# 0001: Initial Repository Structure

Status: Accepted for the OOT-1 scaffold; revisit as application requirements emerge.

## Baseline
Follow the [Standard .NET Repository Structure](https://onyxdigital.atlassian.net/wiki/x/C4C6m).
The initial repository contained README.md, LICENSE, and Visual Studio ignore rules.

## Decisions
- Use Onyx.OpenTerminal.sln and .NET 10, with SDK minimum 10.0.301 and stable
  roll-forward within major version 10. This matches the SDK used for validation.
- Start with Onyx.OpenTerminal.UI as a class library and a matching xUnit project.
  No UI host/framework is selected. The standard's API/Application/Domain/
  Infrastructure projects are examples; create them only when required.
- Use Directory.Build.props for shared validation settings. Retain explicit
  template package versions in the single test project. Central package
  management and NuGet.config are unnecessary until shared versions or private
  sources are needed.
- Use GitHub Actions for build and test automation under `.github/workflows/`
  (updated in OOT-3). Branch policies, deployment, and release automation are
  separate work.
- Use shared AI.md guidance, an AGENTS.md entry point, portable specialised
  briefs under agents/, and SKILL.md definitions under .agents/skills/.
  Discovery is tool-dependent; explicit file loading is the supported fallback.
- Track documentation in otherwise empty folders. Deployment subdirectories
  and pipeline templates will be added when concrete assets exist.

## Consequences
The scaffold builds and tests without imposing application architecture or a UI
framework. Gitflow requires PRs into develop, test, and main; repository branch
protection settings and creation of test are not performed by this scaffold.
