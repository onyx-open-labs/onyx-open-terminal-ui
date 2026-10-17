---
name: github-prod-merge-action
description: Implement or verify test-to-main production promotion using validated test artifacts without repeating passed builds and checks.
---

# GitHub Production Merge Action

Read AI.md and github-pipeline-policy for approved-merge triggers. Own prod.yml,
build/promote-prod.ps1 and build/prepare-prod.ps1. Read deploy/PRODUCTION.md.
Reuse test artifacts and OOT-11's signature verifier; do not duplicate helpers.
Require a merged same-repository test PR into main and exact merge-SHA checkout.
Compare full source trees; changed production inputs must return through test.
Resolve the merged develop-to-test PR and its successful run attempt. A closed-PR
run reports the head SHA, while test checkout validates the merge SHA. Require
all expected validation, packaging, smoke and release jobs to have passed.
Verify candidate tag/commit, checksums, identity, PASS smoke and application
signature evidence, then recheck installer trust/publisher/timestamp. Missing
evidence or OOT-11 integration/configuration blocks publication.
Promote exact installers and archives. No restore, compilation, security scans,
unit tests or installer smoke reruns in prod. Preserve signed candidate filenames
and internal versions; production v<base> tags the main merge. Record both commits
and workflow URLs. Never overwrite tags; stage every asset in a draft first.
Run tests/ReleasePipeline/test-promote-prod.ps1 and parse changed scripts/YAML.
Keep helper tests in test validation after merge, not in prod. Distinguish offline
mocks from hosted execution, signature trust and manual clean-machine checks.
