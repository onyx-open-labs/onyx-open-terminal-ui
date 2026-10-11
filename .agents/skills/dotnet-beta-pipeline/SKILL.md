---
name: dotnet-beta-pipeline
description: Configure, repair, or verify this repository's GitHub Actions beta pipeline for develop-to-test promotion, Windows installer packaging, release metadata, artifacts, and tester handoff. Use for beta pipeline work, not ordinary unit-test changes or production release setup.
---

# .NET Beta Pipeline

Read AI.md and the current requirements before changing the pipeline. This skill
captures the OOT-5 beta workflow; adapt it to explicitly requested changes rather
than treating the current implementation as a permanent constraint.

## Repository entry points

Resolve repository-relative paths from the repository root:

- `.github/workflows/test-beta.yml`: promotion trigger, validation and packaging jobs.
- `build/package-beta.ps1`: self-contained publishing, versioning and installer compilation.
- `build/install-compiler.ps1`: official compiler download and signature verification.
- `deploy/installer.iss` and `deploy/version.json`: installer definition and base version.
- `deploy/BETA-TESTING.md`, `deploy/KNOWN-ISSUES.md`, and
  `deploy/test-results-template.md`: tester handoff and verification evidence.
- `global.json` and the WinUI project under `src/`: SDK and platform requirements.

Reuse these files; keep substantial procedures in the tester documentation rather
than duplicating them here. Use [repository-validation](../repository-validation/SKILL.md)
for solution restore, build and test checks. Load
[dotnet-github-security](../dotnet-github-security/SKILL.md) only when security
workflow configuration is part of the requested work.

## Promotion and release identity

Preserve the current trigger: closed pull requests targeting `test`, gated on a
successful merge from this repository's `develop` branch. Closing without merging
may create skipped jobs; it must not execute validation or packaging. Other source
branches and forks must not package candidates. Packaging depends on successful
validation. Keep permissions limited to the operations actually performed.

Check out the event's merge commit in both validation and packaging. Test, build,
and record the same commit; checking out a moving branch can package later changes.
Generate the change list from the prior test commit to the candidate commit, and
record the source commit and workflow URL in release.json.

Use deploy/version.json as the base version source. Candidate versions currently
include the workflow run number and retry attempt. Preserve uniqueness on reruns
and use installer-compatible numeric file versions alongside the full beta label.
Verify agreement between the installer, release.json and displayed application
version. Check numeric version limits when changing the version scheme.

## Packaging and artifacts

Publish the supported x64/x86 targets on Windows with the pinned SDK. Bundle .NET
and Windows App SDK runtimes so testers need no development SDK. Compile the
installer with product `Onyx Open Terminal`, publisher `Onyx Open Labs`, licence
`MIT`, and candidate version; include the licence text. Preserve stable installer
identity and per-user installation paths so same-architecture upgrades replace
the existing installation.

Download compiler releases from the official vendor and verify authenticity before
execution. When changing compiler versions, check current official documentation,
compatibility and licensing; do not bypass failed signature checks.

Propagate failures from restore, tests, publishing, compilation and artifact upload.
Inspect generated installer metadata and handoff contents. Upload installers,
release identity, changes, known issues, instructions and a pending results record.
Retain candidates and test reports for the documented 90 days, subject to repository
limits. Keep generated outputs and downloaded tools under ignored artifacts/.

## Verification and reporting

Parse changed workflow YAML and PowerShell, inspect event guards and commit
references, and validate changed packaging for each affected architecture. Reuse
repository-validation when application or build changes require solution checks.
For documentation-only edits, check links and diffs; do not rebuild solely to
validate wording. Expose new skills in the existing Solution Explorer convention.

Follow deploy/BETA-TESTING.md for clean installation, launch/version verification,
uninstallation and upgrade from the previous verified beta. Record evidence per
candidate and architecture. Only the first beta has no upgrade baseline; a missing
or expired baseline for later betas is a blocked check. Check settings/data
preservation when those features exist; record a reason for any N/A result.

Keep README badges linked to the actual dedicated workflows. A passing packaging
badge does not mean manual installer checks passed. Represent absent workflows as
not configured; do not invent passing status or add production workflows implicitly.

After an authorized promotion, inspect hosted job results and downloaded artifacts
against the recorded commit and version. Report local validation, hosted workflow
verification, and manual installer/upgrade evidence separately. Packaging success
alone does not satisfy all OOT-5 acceptance criteria. Follow AI.md's existing merge
authorization policy; using this skill grants no additional permission.
