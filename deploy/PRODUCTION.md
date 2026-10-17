# Production promotion

Review and manually merge develop into test, wait for its successful pipeline
and published pre-release, then review and merge test into main to start prod.
PR open/update/review and direct pushes execute no prod jobs. Unmerged closure
can create a skipped workflow entry. Only a same-repository test PR is eligible.

Prod compares the entire main/test source trees and resolves the matching merged
develop-to-test PR and successful workflow attempt. Required validation, both
packaging jobs, both smoke jobs and pre-release publication must have passed.
Changed source or missing evidence blocks publication; pass changes through
develop/test first. Persistent release assets avoid Actions artifact expiry.

Prod downloads both installers, architecture evidence archives, unit-test archive
and checksums. It verifies hashes, candidate identity, matching PASS smoke and
application-signing evidence, and rechecks installer Windows trust, publisher and
timestamp using OOT-11's shared verifier. Set SIGNING_CERTIFICATE_SUBJECT to the
approved certificate subject. OOT-11 must be merged/configured and signed test
artifacts generated first. No restore/build, unit tests, security scans or installer
smoke tests rerun in prod: the promoted binaries are unchanged.

The production tag v<deploy/version.json version> points to the main merge.
Installers keep their tested filenames and installed candidate version, including
-test.<run>.<attempt>, to preserve exact signed bytes. The stable release title/tag
denotes production approval; changing internal version requires a new build and
validation. promotion.json and notes identify both commits, candidate version and
workflow URLs. Bump the base version through develop/test for the next release.

All assets upload to a draft before publication. Never overwrite production tags.
On failure inspect diagnostics and any draft; remove an unpublished failed draft/tag
only after review before retrying the same version. Published releases require a
new base version. Prod does not claim manual clean-machine/upgrade checks passed;
consult the attached tester records. Diagnostic artifacts remain available 90 days.

Only promotion has contents:write; lookups also need actions:read. Offline helper
tests mock GitHub and certificate trust and do not prove hosted publication or
real Windows trust. Branch protection remains governed by AI.md.
