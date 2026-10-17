---
name: github-test-merge-action
description: Create, repair, or review this project's GitHub Actions workflow after develop merges into test, including exact-commit validation, test installer packaging, installer smoke tests and GitHub pre-releases. Use for test promotion and shared installer/release helpers, not develop security scans or PR event configuration.
---

# GitHub Test Merge Action

## Responsibility and entry points

Own `.github/workflows/test.yml` and its promotion jobs. Shared installer
and release mechanics live in `build/package-test.ps1`, `build/install-compiler.ps1`,
`build/test-installer.ps1`, `build/publish-test.ps1`, `deploy/installer.iss` and
`deploy/version.json`. Release failure-guard tests live in
`tests/ReleasePipeline/test-publish-test.ps1`; tester procedures and evidence
requirements live in `deploy/TESTING.md` and `deploy/test-results-template.md`.
Reuse these sources rather than duplicating their procedures in another workflow.

Use [github-develop-merge-action](../github-develop-merge-action/SKILL.md) for
develop build/security integration and
[github-pipeline-policy](../github-pipeline-policy/SKILL.md) for approval enforcement.
Use [repository-validation](../repository-validation/SKILL.md) for local solution
checks when application/build changes require them.

Run tests/ReleasePipeline/test-publish-test.ps1 in validation before packaging.
Keep all installer checks after the approved merge; never restore a PR/manual workflow.

## Promotion identity

Preserve closed PRs targeting `test`, gated on a successful merge from this
repository's `develop` branch. Unmerged closures, other source branches and forks
must not execute promotion jobs. Checkout the event's exact merge commit in
validation, packaging, smoke and publishing jobs; never substitute a moving branch.
Retest the promoted commit even when develop checks passed: test can contain a
different merge result. Do not repeat the develop security scans here.

Read the base version from deploy/version.json. Preserve unique candidate versions
across runs/attempts, compatible numeric installer/file versions, and agreement
between release.json, installer metadata and the displayed application version.
Record the source commit/workflow and changes since the previous test commit.

## Package and smoke-test the actual installers

Reuse the packaging helpers for supported x64/x86 self-contained .NET/Windows App
SDK payloads, including generated XAML resources. Preserve the stable per-user
installer identity, Onyx Open Terminal product, Onyx Open Labs publisher, MIT
licence and candidate version. Verify compiler authenticity when downloading it.
Propagate command failures and keep generated files under ignored artifacts/.

Packaging depends on validation. Promotion smoke jobs download the actual
candidate artifacts onto separate Windows runners and call test-installer.ps1.
Do not reimplement the install/window/version/uninstall checks in YAML. Preserve
always-uploaded failure diagnostics and 90-day Actions artifact retention.
Read deploy/TESTING.md for the remaining clean-machine and upgrade checks;
hosted smoke success does not prove those manual requirements passed.

## Publish GitHub pre-releases

Publishing depends on validation, packaging and both smoke jobs succeeding.
Only this job needs contents: write; other promotion jobs remain read-only.
Use publish-test.ps1 to verify matching PASS evidence and candidate identity before
publishing tag v<version> at the exact tested commit. Attach both installers,
architecture handoff/smoke archives, solution test reports and SHA256 checksums.
Notes must distinguish automated success from pending manual checks.

Never overwrite/reuse published tags. A publishing/upload failure can leave an
unpublished draft; follow the documented full-workflow retry procedure so all
artifacts share the new attempt/version. Release assets remain separate from the
90-day Actions artifact expiry. PR/review builds must not publish public releases.

## Verify and report

Parse changed YAML/PowerShell and check promotion guards, job dependencies,
artifact names and narrowly scoped permissions. Run release preparation/failure
checks when changing publishing, validate packaging for affected architectures,
and reuse repository-validation only when solution changes require it.
Check the test badge against this workflow, not another branch's run.

Separate local results, hosted jobs, actual pre-release publication and manual
verification in reports. After an authorized promotion, verify release tag/commit,
assets, notes and recorded smoke results before claiming publication succeeded.

Follow [github-pipeline-policy](../github-pipeline-policy/SKILL.md) for mandatory
approval enforcement, canonical stage names and negative trigger checks.
