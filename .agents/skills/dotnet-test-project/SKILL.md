---
name: dotnet-test-project
description: Create or repair a .NET test project and solution integration, including framework compatibility, test discovery and local full-suite failure handling. Use for test-project infrastructure, not GitHub Actions orchestration or routine additions to an existing test project.
---

# .NET Test Project Setup

## Inspect before choosing dependencies

Read the repository AI guidance, solution, shared build properties, SDK pin,
production project, existing test projects, and build scripts. Reuse existing
framework and runner conventions when compatible. Otherwise choose supported
versions using current official framework and runner documentation; do not copy
package versions from this skill or an old scaffold.

Match the production target framework and any Windows platform requirements.
Check the test runner architecture, runtime identifier, and solution platform
mappings together. In this repository the WinUI host defaults to x64 and also
supports x86; a test project referencing it must build for the matching platform.
Do not introduce a second runner or coverage dependencies unless needed.

## Integrate and add a useful test

Place the project under tests/ with a name matching the production project.
Add a production ProjectReference and include it under the solution's tests
folder, with build mappings for the supported solution configurations. Keep
production projects independent of test projects.

Add a focused test of existing production behavior or a meaningful application
configuration contract. Avoid always-passing assertions and production changes
whose sole purpose is making a scaffold test possible. Reuse an existing test
project when it already covers the requested scope.

For WinUI, prefer testing logic or metadata without activating a window when
that satisfies the task. XAML configuration tests may copy the production XAML
into test output and inspect it; describe them as configuration checks, not
proof of runtime UI behavior. UI activation tests need an appropriate desktop
and dispatcher setup and should not be assumed suitable for a headless CI job.

## Verify the runner and failure path

Use [repository-validation](../repository-validation/SKILL.md) for the root
restore, build, test, and diff checks. Confirm the output reports discovered
and executed tests with a positive test count; a successful command with no
tests does not validate the setup.

Exercise the documented full-suite entry point, not only the test project.
In this repository it is `pwsh -NoProfile -File ./build/test.ps1` from the root.
It must build before using --no-build and propagate restore, build, or test
failure to the calling process.

Temporarily make one new assertion fail and run that same entry point. Verify
that the failure comes from the assertion and the process exit code is non-zero,
rather than from restore or build errors. Preserve the original test source
and restore it even if execution is interrupted or errors. Rebuild and rerun
the final suite after restoring it; never commit the deliberate failure.

## Document the result

Update the setup documentation with prerequisites, a non-interactive root
command for the full suite, required OS and architecture, and exit-code behavior.
Reuse the existing build entry point where possible. When workflow changes are
also requested, use the owner listed in docs/ai-workflow.md; this skill does not
define branch triggers, scanner jobs, installer packaging or release publishing.
Report the passing test count, build result, and
observed failure and final success exit codes, including any verification gaps.
