# Beta installation and verification

Download the matching x64 or x86 artifact from the successful `Package beta after
develop merges into test` GitHub Actions run. Extract the ZIP, read release.json,
CHANGES.txt and KNOWN-ISSUES.md, then run the setup executable. Installation is
per-user and includes the .NET and Windows App SDK runtimes. MIT terms are shown
by setup and LICENSE is installed with the application. Use the Start menu shortcut.

Candidates use deploy/version.json plus the workflow run number and retry attempt:
`0.1.0-beta.<run>.<attempt>`. release.json links the candidate to its exact commit
and workflow. The executable file version uses the numeric `<base>.<run>` format.

## Clean installation check

### Automated installer smoke test

The beta promotion workflow downloads each x64/x86 installer onto a separate
Windows runner, installs it silently in a temporary directory, checks application
resources, version/publisher/licence metadata and the Start menu shortcut, then
launches the installed executable from a different working directory. It requires
a visible, responsive window with the exact candidate version to remain open for
five seconds. An early exit or a 60-second window timeout fails the workflow.
Finally it uninstalls and checks removal of the executable, shortcut and Installed
Apps registration. Cleanup is attempted even when launch fails.

The `Validate installer on pull requests` workflow runs the same checks before
merging application, packaging or pipeline changes. Its build is a review candidate;
the promotion workflow tests the exact installer artifacts supplied to beta testers.
Read the explicitly named installer smoke jobs, not just the unit-test/package jobs.
Each architecture uploads `installer-smoke-*` (promotion) or `pr-installer-smoke-*`
(review) evidence, including result.json, smoke.log, install/uninstall logs and
relevant Windows Application events. Failure evidence uploads even when testing fails.

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

Retrieve the most recent previously verified beta of the same architecture from
its workflow artifacts. Install it in a fresh VM and launch it. When settings or
data features exist, create representative settings/data and record their values.
Close it and run the new installer without uninstalling the old version. Launch,
verify the new version, preserved settings/data, available core functions, one
Installed Apps entry and a working shortcut. Finally uninstall and record results.
For the first beta, record upgrade as N/A. A missing or expired baseline for a
later beta is a blocked check, not a pass or first-beta exemption.

## Handoff and retention

Clean-machine and upgrade verification remain manual; automated installer smoke
results are recorded separately from those checks.
Do not mark OOT-5 complete or approve a candidate without the required recorded
results. Attach completed test-results.md and evidence to the Jira release work.
Report bugs in Jira with candidate version, commit, architecture, reproduction
steps and logs; GitHub issues can be used where Jira access is unavailable.
CHANGES.txt lists commits introduced by this promotion relative to the previous
test branch commit. Review and summarise these changes for testers; if earlier
candidates were not verified, also review the diff from the last verified beta.

Candidate and automated test artifacts are retained for 90 days, subject to the
repository/organisation retention limit. Keep verified candidates available within
that period; download archival copies before expiry if longer retention is needed.
For rollback, back up user data, uninstall the candidate and reinstall the previous
verified beta. Do not assume data migrated by a newer version supports downgrade.
