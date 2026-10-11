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

Installer/upgrade verification is manual until application automation exists.
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
