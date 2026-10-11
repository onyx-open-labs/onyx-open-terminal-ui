---
name: github-installer-pr-action
description: Create, repair, or review this project's pre-merge installer validation workflow for PRs into develop or test, including PR path filters, same-repository guards, smoke-test orchestration and release preparation checks. Use for installer-smoke.yml, not post-merge promotion or publishing releases.
---

# GitHub Installer PR Action

## Responsibility

Own `.github/workflows/installer-smoke.yml`: PR/manual triggers, changed-path
filters, job guards, checkout identity, helper invocation and review evidence.
The shared packaging, installer smoke and release helpers belong to
[github-test-merge-action](../github-test-merge-action/SKILL.md); consult its
relevant sections when changing those helpers. Keep develop integration/security
checks in [github-develop-merge-action](../github-develop-merge-action/SKILL.md).

## Validate before merging

Preserve PR targets develop/test and the existing manual trigger. Include paths
that affect application payloads, packaging/deployment scripts, workflow setup,
SDK/build properties and release tests. Keep packaging/smoke jobs restricted to
same-repository PRs or explicit manual runs; retain read-only contents permissions.

For PRs, validate the checked-out PR merge result and record git rev-parse HEAD
in review metadata. Do not confuse this synthetic merge with a later promotion
commit. For manual runs, record the selected ref's actual checked-out commit.

Call the existing compiler/packaging helpers for the x64/x86 review matrix and
then test-installer.ps1 against each generated installer. Keep the installer
checks in the helper rather than copying them into workflow steps. Run
tests/ReleasePipeline/test-publish-beta.ps1 for preparation/failure guards; its
CLI is mocked, and it must not create tags or public releases.

Upload review smoke evidence even on failure. A PR result does not replace the
promotion workflow's smoke tests: promotion tests the actual published candidate
artifacts. Do not add develop security scans or repeat their build/test pipeline
here. Add another check only when it covers a distinct requested requirement.

## Verify changes

Parse YAML, confirm event/path filters and job permissions, and exercise affected
helpers through their existing tests. For shared helper changes, inspect both
this workflow and its promotion caller for compatible arguments/artifact names.
Report the tested PR commit, both architecture results and uploaded evidence.
Keep local simulation and hosted installer verification distinct.
