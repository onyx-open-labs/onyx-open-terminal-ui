---
name: dotnet-github-security
description: Configure or maintain NuGet Audit, Gitleaks, and CodeQL security checks in GitHub Actions for .NET repositories, including scan scope, reporting, and failure verification. Use for security workflow setup or repair, rather than routine application changes or test-project creation.
---

# .NET GitHub Security Checks

## Inspect the repository and requested scope

Read the repository AI guidance, existing workflows, SDK pin, solution,
production/test project targets, and shared build properties. Check repository
visibility and relevant security settings through available GitHub tools.
Preserve the requested event, branches, tools, and failure policy. A request to
configure scans does not authorize changing visibility, buying a license,
enabling unrelated services, or merging a PR.

Use the existing workflow as the implementation reference; do not copy its
versions into another repository without checking current official releases,
SDK compatibility, runner requirements, and tool licensing. Verify changed
command syntax using the repository's installed SDK and tool help.

In this repository, extend `.github/workflows/develop-build-test.yml`. Its
current scope is merged PRs targeting `develop`, with NuGet Audit, Gitleaks CLI,
and CodeQL. Dependabot was removed by user request; preserve that scope unless
the user requests a change. The WinUI solution requires Windows for restore,
build, and CodeQL extraction. Use the SDK in `global.json`.

## Preserve event and checkout semantics

For a merge-only PR workflow, filter `pull_request` to `types: [closed]` and
the requested base branch, then guard every job with
`github.event.pull_request.merged == true`. An unmerged closure can create a
skipped workflow entry; describe this accurately instead of claiming no event
occurred. Do not substitute an unrestricted push trigger, which includes
direct pushes, or add PR/scheduled triggers without a requested scope change.

Explicitly check out the requested updated integration branch. Record the
actual scanned commit and associate uploaded code-scanning results with that
branch and SHA; do not assume the event SHA matches a later branch checkout.
Keep independent scans independent of the build/test job so one failure does
not prevent other checks. Give jobs timeouts and grant write permissions only
to jobs that need them, such as CodeQL's `security-events: write`.

## Configure the scanners

### NuGet Audit

Audit direct and transitive dependencies explicitly with `NuGetAudit=true`
and `NuGetAuditMode=all`; choose the minimum severity from the requested policy
and existing conventions. This repository checks every severity with
`NuGetAuditLevel=low` and treats restore warnings as errors. Force restore when
needed to ensure the audit is evaluated rather than relying on old assets.

Do not treat a successful package-list command as proof that no vulnerable
packages exist: its report and process status serve different purposes. Use
restore audit warnings promoted to errors, or an explicitly validated report
gate, to enforce the chosen policy. Account for audit-source failures so a
failed audit is not reported as a clean scan. Save a JSON report including
transitive dependencies when available; use SDK-supported solution arguments
and preserve native exit codes when piping output to a file in PowerShell.

### Gitleaks

Distinguish the free Gitleaks CLI from the separately licensed GitHub Action
wrapper, especially for organization repositories. A CLI job can download a
pinned release, verify its archive against the published SHA-256 checksum, and
run without a wrapper license. Fail installation on HTTP/checksum errors.

Fetch sufficient Git history and scan the intended scope. For integration
branch history, use full checkout history and the commits reachable from its
checked-out HEAD; do not accidentally scan every unrelated fetched branch.
Redact secret values in logs and reports. Preserve the scanner's non-zero
status for findings and errors, and upload its redacted report even on failure.
Do not add broad exclusions or a baseline to make a failing scan pass without
reviewing the findings and the user's intended policy.

### CodeQL

Confirm eligibility before adding uploads: public GitHub repositories can use
free code scanning; private/internal repositories require appropriate GitHub
Code Security access. If unavailable, report the gap rather than silently
omitting the scan or changing repository visibility. Check default versus
advanced setup compatibility; do not promise that uploads will work while
default setup conflicts with the requested custom workflow.

For WinUI C#, initialize CodeQL in manual build mode, then restore and build
the solution on Windows before analysis. Ensure compilation actually occurs;
an up-to-date incremental build can leave extraction without the expected
code. Use the requested query suite; this repository uses `security-extended`.

Successful analysis/upload does not itself mean there are no findings. When
the policy is to fail on findings, inspect the generated SARIF after analysis
and apply an explicit gate. This repository fails on any reported result.
Missing or malformed reports must not pass as clean. Publish results to
GitHub code scanning and retain a SARIF artifact even when the gate fails.

## Verify and document

Use [repository-validation](../repository-validation/SKILL.md) for the root
restore, build, test, and diff checks. Parse the changed YAML, confirm branch
filters and every job's merge guard, and verify solution item paths if added.
Run locally supported scan commands and inspect their reports. For a new or
changed findings gate, exercise clean, finding, and missing-report cases using
temporary fixtures outside tracked source; never inject a real secret.

Keep reports, downloaded tools, and synthetic fixtures out of commits. Update
the README with triggers, scanner scope, failure policy, report locations, and
any required settings. Expose new workflow/skill files in Solution Explorer
when following this repository's existing solution-folder convention.

Distinguish local checks from hosted verification: local builds and synthetic
SARIF tests do not prove CodeQL extraction/upload or the actual GitHub event.
After an authorized merge, inspect the hosted jobs, scanned commit, reports,
and code-scanning alerts before claiming end-to-end success. Report pending
hosted verification when merging is outside the current authorization.

## Official references

Consult the relevant current source when selecting versions or changing that
tool's configuration:

- [GitHub PR workflow events](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#pull_request)
- [NuGet Audit configuration and CI behavior](https://learn.microsoft.com/en-us/nuget/concepts/auditing-packages)
- [.NET package-list syntax](https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-package-list)
- [Gitleaks CLI, flags, and releases](https://github.com/gitleaks/gitleaks)
- [Code scanning eligibility](https://docs.github.com/en/code-security/concepts/code-scanning/code-scanning)
- [CodeQL Action build modes and supported versions](https://github.com/github/codeql-action)
- [CodeQL workflow configuration](https://docs.github.com/en/code-security/reference/code-scanning/workflow-configuration-options)
