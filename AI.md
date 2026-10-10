# Repository AI Guidance

## Purpose and Boundaries

This repository contains the Onyx Open Terminal UI solution. The initial
production project is a framework-neutral .NET 10 library under src/.
Do not choose a UI framework or add application features as part of scaffolding.
Keep production code under src/, matching tests under tests/, documentation under
docs/, build automation under build/, and deployment assets under deploy/.

## Validation

Run from the root:
```text
dotnet restore Onyx.OpenTerminal.sln
dotnet build Onyx.OpenTerminal.sln --configuration Release --no-restore
dotnet test Onyx.OpenTerminal.sln --configuration Release --no-build
```

Use nullable reference types, explicit responsibility-based names, four-space
C# indentation, and focused tests for behaviour changes. Test projects may
reference production projects; production projects must never reference tests.
Keep UI concerns separate from future domain and infrastructure concerns.

## Changes and Gitflow

Preserve existing work. Keep changes focused, justify dependencies, update
documentation when behaviour or setup changes, and never commit credentials,
build outputs, or personal settings. Work from develop on a feature branch.
Use pull requests for merges into develop, test, and main. Do not directly push
to these branches or merge a pull request without the user's authorization.

## Agents and Skills

Read docs/ai-workflow.md. Specialised briefs are in agents/; reusable skills are
in .agents/skills/. Select a brief by responsibility and give it the task scope,
relevant files, constraints, and required checks. Delegation is optional and
requires tooling that supports it; these files do not themselves start agents.
Follow root guidance in addition to a selected brief or skill.
