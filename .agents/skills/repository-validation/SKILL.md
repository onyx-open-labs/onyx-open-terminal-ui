---
name: repository-validation
description: Run shared local validation of this project's .NET solution after application, project, dependency or build changes. Use as a helper for workflow skills; it does not configure GitHub Actions.
---

# Repository Validation

1. Read AI.md and the changed files.
2. From the root, execute AI.md's Validation restore/build/test sequence, stopping
   and reporting failures. AI.md owns the canonical commands; do not maintain a
   second command list in each workflow skill.
3. Run git diff --check and inspect git status for generated or sensitive files.
4. Report the build result, executed test count and actionable failures. Local
   success does not prove hosted workflow triggers, scanners or installer behavior.
   For skill/documentation-only changes, validate metadata, links and solution item
   paths instead of rebuilding the application solely to check wording.
