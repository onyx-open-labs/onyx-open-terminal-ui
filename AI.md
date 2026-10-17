# Repository AI Guidance

## Purpose and Boundaries

This repository contains the Onyx Open Terminal UI solution. The production
project is the .NET 10 WinUI desktop application under src/.
Keep changes focused on the requested application features.
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

## Pipeline approval policy

Name pipelines `develop`, `test` and `prod`; the production Git branch is `main`.
Run GitHub Actions jobs only after an approved PR merges into the matching branch.
Do not add push, PR-open/update/review, schedule or manual-dispatch triggers.
Use `pull_request`, `types: [closed]`, a target branch filter and merged job guards.
An unmerged closure may create a skipped workflow entry but must execute no jobs.
Enforce approval through branch protection on develop/test/main: require one
independent approving review, dismiss stale approvals, enforce rules for admins,
block direct/force pushes and deletion, and retain no bypass allowance.
Do not require pre-merge Actions checks when Actions only run after merging.
A merged flag alone does not prove approval. Verify repository settings as well
as YAML. Use the exact event merge commit for every checkout.
The prod pipeline is not implemented; do not invent release behavior without requirements.

## Agents and Skills

Read docs/ai-workflow.md. Specialised briefs are in agents/; reusable skills are
in .agents/skills/. Select a brief by responsibility and give it the task scope,
relevant files, constraints, and required checks. Delegation is optional and
requires tooling that supports it; these files do not themselves start agents.
Follow root guidance in addition to a selected brief or skill.

Select the skill owning the workflow being changed:

- [github-develop-merge-action](.agents/skills/github-develop-merge-action/SKILL.md):
  post-merge develop build/tests and security scans.
- [github-test-merge-action](.agents/skills/github-test-merge-action/SKILL.md):
  develop-to-test promotion, shared installer/release helpers, smoke tests and pre-releases.
- [github-pipeline-policy](.agents/skills/github-pipeline-policy/SKILL.md):
  approval enforcement, stage naming and trigger validation.

Use repository-validation for shared local solution checks and dotnet-test-project
for test-project setup. Workflow skills reuse these helpers rather than owning
another copy of their procedures. See docs/ai-workflow.md for the responsibility map.
