# Test installation and verification

Download the matching x64 or x86 installer from the repository's GitHub Releases
page. Successful develop-to-test promotions publish a versioned pre-release only
after solution validation and both installer smoke tests pass. Download the matching
evidence ZIP as well and read release.json,
CHANGES.txt and KNOWN-ISSUES.md, then run the setup executable. Installation is
per-user and includes the .NET and Windows App SDK runtimes. MIT terms are shown
by setup and LICENSE is installed with the application. Use the Start menu shortcut.

Candidates use deploy/version.json plus the workflow run number and retry attempt:
`0.1.0-test.<run>.<attempt>`. release.json links the candidate to its exact commit
and workflow. The executable file version uses the numeric `<base>.<run>` format.

Each pre-release uses tag `v<version>` at the exact tested merge commit and includes
both setup executables, architecture evidence ZIPs, solution test reports and
SHA256SUMS.txt. Release notes identify the source/workflow, changes, known issues
and pending manual checks. No pre-merge PR builds run. An upload failure may
leave an unpublished draft; inspect the failed publishing job and rerun the entire
promotion workflow so all artifacts share the new attempt/version. Published
versions are never overwritten. GitHub release assets do not use the Actions
artifact 90-day expiry; retain prior test releases for upgrade verification.

## Clean installation check

### Automated installer smoke test

The test promotion workflow downloads each x64/x86 installer onto a separate
Windows runner, installs it silently in a temporary directory, checks application
resources, version/publisher/licence metadata and the Start menu shortcut, then
launches the installed executable from a different working directory. It requires
a visible, responsive window with the exact candidate version to remain open for
five seconds. An early exit or a 60-second window timeout fails the workflow.
Finally it uninstalls and checks removal of the executable, shortcut and Installed
Apps registration. Cleanup is attempted even when launch fails.

Installer validation runs only after an approved PR merges into test.
Read the installer smoke jobs as well as the unit-test/package jobs.
Each architecture uploads installer-smoke-* evidence, including result.json,
smoke.log, install/uninstall logs and relevant Windows Application events. Failure evidence uploads even when testing fails.

Hosted runners contain development tools and these checks do not prove operation
on a clean Windows machine or verify upgrade/data preservation. Complete the
following manual checks as well. A downloadable installer from a failed run is
not a verified candidate.

### Manual clean-machine verification

Use a clean Windows VM of the matching architecture without a prior installation
or preinstalled development runtimes. Install, launch, check the version displayed
in the window title against release.json, and verify the welcome screen. Check
publisher and version in Windows Installed Apps and the installed LICENSE file.
Uninstall via Windows Installed Apps; verify the application and shortcut are gone.
Record results in test-results.md, with screenshots/logs as evidence.

## Upgrade check

Retrieve the most recent previously verified test release of the same architecture from
GitHub Releases (or workflow artifacts for older candidates). Install it in a fresh VM and launch it. When settings or
data features exist, create representative settings/data and record their values.
Close it and run the new installer without uninstalling the old version. Launch,
verify the new version, preserved settings/data, available core functions, one
Installed Apps entry and a working shortcut. Finally uninstall and record results.
For the first test release, record upgrade as N/A. A missing or expired baseline for a
later test release is a blocked check, not a pass or first-release exemption.

## Handoff and retention

Clean-machine and upgrade verification remain manual; automated installer smoke
results are recorded separately from those checks.
Do not mark OOT-5 complete or approve a candidate without the required recorded
results. Attach completed test-results.md and evidence to the Jira release work.
Report bugs in Jira with candidate version, commit, architecture, reproduction
steps and logs; GitHub issues can be used where Jira access is unavailable.
CHANGES.txt lists commits introduced by this promotion relative to the previous
test branch commit. Review and summarise these changes for testers; if earlier
candidates were not verified, also review the diff from the last verified test release.

Candidate and automated test artifacts are retained for 90 days, subject to the
repository/organisation retention limit. Keep verified candidates available within
that period; download archival copies before expiry if longer retention is needed.
For rollback, back up user data, uninstall the candidate and reinstall the previous
verified test release. Do not assume data migrated by a newer version supports downgrade.
