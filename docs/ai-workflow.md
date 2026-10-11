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
Skills live in .agents/skills/<skill-name>/SKILL.md. Each file has YAML name and
description metadata followed by steps. The repository-validation skill is the
initial example. Use [dotnet-test-project](../.agents/skills/dotnet-test-project/SKILL.md)
when adding or repairing test infrastructure; it reuses repository-validation
for solution checks. Tools supporting this discovery convention may expose them;
otherwise read the file explicitly and execute the steps.
Use [dotnet-github-security](../.agents/skills/dotnet-github-security/SKILL.md)
for NuGet Audit, Gitleaks, and CodeQL workflow setup or repair. It covers
eligibility, merge triggers, scan scope, reports, and failure verification,
and reuses repository-validation rather than duplicating solution checks.
Use [dotnet-beta-pipeline](../.agents/skills/dotnet-beta-pipeline/SKILL.md)
for develop-to-test promotion, Windows beta installers, version metadata,
artifacts, status badges, and installation/upgrade verification handoff.
It reuses the existing packaging scripts and repository-validation skill, and
distinguishes local checks, hosted workflow results, and manual verification.
No automatic discovery or delegation was verified in an external agent runtime.
The manual fallback requires only file reading and a shell, and was exercised
during scaffold validation.

Add new briefs using purpose, responsibilities, scope, and validation sections.
Add skills using the same metadata and procedural format as the example.
Avoid duplicating root guidance. Add local AI.md files only for real additional
project constraints.
