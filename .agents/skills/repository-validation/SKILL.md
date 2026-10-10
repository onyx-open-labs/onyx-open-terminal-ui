---
name: repository-validation
description: Validate this repository's .NET scaffold after project, dependency, or build changes.
---

# Repository Validation

1. Read AI.md and the changed files.
2. From the root, run dotnet restore Onyx.OpenTerminal.sln.
3. Run dotnet build Onyx.OpenTerminal.sln --configuration Release --no-restore.
4. Run dotnet test Onyx.OpenTerminal.sln --configuration Release --no-build.
5. Run git diff --check and inspect git status for generated or sensitive files.
6. Report outcomes and actionable failures. Do not commit, push, or merge unless authorized.
