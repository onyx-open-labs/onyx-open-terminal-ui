# Deployment Assets

Place deployment scripts, environment templates, and infrastructure here when
a deployment target is selected. No deployment is implemented in OOT-1.
Never commit environment secrets or machine-specific settings.

## Beta packaging

See BETA-TESTING.md for installer smoke evidence, manual verification, upgrade testing and
90-day artifact retention. deploy/version.json is the release base version source.
The test-beta workflow validates the exact merge commit and packages x64/x86
per-user installers with Inno Setup 6.7.3 downloaded from the official vendor
release and verified using its Authenticode publisher signature. Separate smoke
jobs download, install, launch and uninstall the actual x64/x86 candidate artifacts.
Pull requests also validate installers before promotion. Manual clean-machine
and upgrade checks remain pending. Build outputs belong in the ignored artifacts/ directory.

After both smoke jobs pass, the promotion workflow publishes a versioned GitHub
pre-release containing installers, tester handoff/smoke evidence, unit-test
reports and checksums. Release notes include changes and pending manual checks.
Only the publishing job has repository content write permission.
