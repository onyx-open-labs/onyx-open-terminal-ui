# Code signing policy

Status: integration prepared; provider enrolment and clean-machine verification pending.
No trusted certificate has been issued or installed by this change.

## Free signing setup

Apply to [SignPath Foundation](https://signpath.org/) for this MIT project.
Eligibility is subject to their [conditions](https://signpath.org/terms.html):
active maintenance, an existing release, open-source components, MFA and a
published signing policy. Confirm eligibility of every bundled dependency.
Chris O'Beirne is the maintainer, reviewer and signing approver. Confirm the
solo-maintainer process with the provider before activation.

After acceptance, add the required attribution to the README and download pages:
"Free code signing provided by SignPath.io, certificate by SignPath Foundation".
Do not claim sponsorship before acceptance. The Foundation certificate's actual
subject may differ from the installer metadata publisher Onyx Open Labs.

Configure the SignPath GitHub trusted-build integration for
onyx-open-labs/onyx-open-terminal-ui. Import signpath/application.xml and
signpath/installer.xml as artifact configurations named application and installer.
Create a signing policy using the approved publicly trusted certificate,
SHA-256 and timestamping. Restrict it to this repository, the test workflow and
GitHub-hosted builds of approved develop-to-test merges. Keep manual signing
approval enabled. Give the API user submitter access only.

Add the repository secret SIGNPATH_API_TOKEN and repository variables:
- SIGNPATH_ORGANIZATION_ID
- SIGNPATH_PROJECT_SLUG
- SIGNPATH_SIGNING_POLICY_SLUG
- SIGNING_CERTIFICATE_SUBJECT: exact certificate Subject distinguished name

Never store certificate private keys or tokens in source or logs. Keys remain
with the provider. Rotate the API token and review provider access when roles
change. Monitor certificate expiry and renew through the provider; after renewal,
update the expected subject if it changes and repeat clean-machine verification.

## Release behavior

develop continues build/test/security checks without signing.
test publishes the application, signs its EXE and DLL, verifies them, compiles
the installer, signs the installer, and verifies it before smoke tests and
publication. Third-party runtime files retain their vendor signatures.
Missing credentials, rejected/timed-out signing, untrusted or unexpected signer,
and absent timestamp stop the release. There is no unsigned fallback.
prod remains unimplemented.

The Inno-generated uninstaller is outside this change's signing coverage.
Assess signing it separately before a production release.

## Verification

On a clean supported Windows machine with no development certificates:
download the actual release installer through a browser, record the Windows
version and original warning text/screenshot, inspect Digital Signatures and
publisher, install and launch, then uninstall. Retain any SmartScreen prompts.
Automated signature checks do not establish SmartScreen reputation or prove the
original warning is resolved. Never disable Windows checks or install a
self-signed root as a public-distribution workaround.

The exact original warning remains unconfirmed. OOT-11 stays open until provider
setup, a signed hosted build, and clean-machine evidence are complete.

Reference: [SignPath GitHub integration](https://docs.signpath.io/trusted-build-systems/github).

