# AI Workflow

AI.md is the canonical shared policy. AGENTS.md is the instruction entry point
for tools that recognize that filename. Other tools must be explicitly given
AI.md; automatic recognition of AI.md is not assumed.

## Specialised Agents
Select agents/scaffold-reviewer.md when a structure review is needed.
Provide its full text with AI.md, the task, relevant files, and validation scope
to an available agent tool. Briefs are manually invoked and have no automatic
registration. A tool without delegation can follow the same brief itself.

## Skills
Skills live in .agents/skills/<skill-name>/SKILL.md. Folder names, YAML names and
Solution Explorer labels match. GitHub workflow skills use the `github-` prefix
and name the integration stage or PR check they own.

| Skill | Owns | Reuses / boundary |
| --- | --- | --- |
| [github-develop-merge-action](../.agents/skills/github-develop-merge-action/SKILL.md) | develop-build-test.yml: merged develop PRs, solution build/tests, NuGet Audit, Gitleaks, CodeQL | Local solution validation; no installer/release jobs |
| [github-test-merge-action](../.agents/skills/github-test-merge-action/SKILL.md) | test.yml: develop-to-test promotion, shared packaging/smoke/release helpers, test pre-releases | Local solution validation and tester procedures; no develop scans or PR event setup |
| [github-pipeline-policy](../.agents/skills/github-pipeline-policy/SKILL.md) | develop/test/prod naming, approved-merge triggers and branch protections | Stage skills own their jobs; no pre-merge/manual installer workflow |
| [github-prod-merge-action](../.agents/skills/github-prod-merge-action/SKILL.md) | prod.yml, promotion helpers and production releases | Reuses signed test artifacts and evidence without rebuilding or rerunning passed tests |
| [dotnet-test-project](../.agents/skills/dotnet-test-project/SKILL.md) | .NET test-project/framework/discovery setup and local full-suite failure handling | Shared local solution validation; routes workflow changes to their stage owner |
| [repository-validation](../.agents/skills/repository-validation/SKILL.md) | Shared local solution validation and clean-diff checks | Canonical commands in AI.md; no workflow configuration |

Choose the workflow owner first; load a supporting skill only for work on its
responsibility. Keep reusable mechanics in build/ scripts and tester procedures
in deploy/ documentation. Update both callers when a shared helper contract changes.
Do not copy helper implementations or create parallel skills for the same workflow.

The test pipeline validates its exact merge commit and actual candidate installers.
CodeQL requires an instrumented compilation. Installer preparation/failure-guard
checks run in test validation, after the approved merge. No PR/manual installer
workflow exists. The prod pipeline (main branch) promotes exact signed test
installers. Its owner is github-prod-merge-action; see deploy/PRODUCTION.md.
Read AI.md for branch approval and trigger policy.

Tools supporting this discovery convention may expose the skills; otherwise read
the selected file explicitly and execute its instructions.
No automatic discovery or delegation was verified in an external agent runtime.
The manual fallback requires only file reading and a shell, and was exercised
during scaffold validation.

Add new briefs using purpose, responsibilities, scope, and validation sections.
Add skills using the same metadata and procedural format as the example.
Avoid duplicating root guidance. Add local AI.md files only for real additional
project constraints.
