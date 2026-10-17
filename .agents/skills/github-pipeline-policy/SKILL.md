---
name: github-pipeline-policy
description: Configure or verify approval enforcement, stage names and GitHub Actions triggers for the develop, test and prod pipelines. Use when changing workflow events, branch protections or pipeline skills.
---

# GitHub Pipeline Policy

OOT-14 permits the develop workflow to scan pushes restricted to the default
branch main. Only code-security runs on these pushes; all other jobs retain
merged-develop-PR guards. CodeQL checks out the exact push github.sha or PR
merge_commit_sha and uploads against github.ref or refs/heads/develop,
respectively. Keep category develop-csharp on both branches for comparison.
This exception supersedes general merge-only and checkout rules.
No push triggers are permitted for test or prod; preserve branch protection.



Read AI.md pipeline approval policy before changing automation.
Inspect every workflow and live branch protection, including automatic CodeQL setup.
Require PRs into develop/test/main, including for admins. Use the solo-maintainer
approval model: Chris reviews and manually merges his PR; that merge is approval.
Set required_approving_review_count to 0 and require_last_push_approval and
require_code_owner_reviews to false. Do not reintroduce independent-review
requirements, enable auto-merge or merge on Chris's behalf without his explicit
merge instruction. Keep direct/force pushes and branch deletion blocked.
Do not add pre-merge, manual, scheduled or unrestricted push runs. Reject stale
required pre-merge checks that would deadlock merging.
Keep workflow names develop/test/prod; main is the prod Git branch.
Use closed PR events with merged guards; explain skipped unmerged-closure entries.
Pin all checkouts to the event merge commit. Preserve least-privilege permissions.
Route build/security work to github-develop-merge-action and installer/release
work to github-test-merge-action; keep helper validation after the approved merge.
Verify branch approval settings through authenticated GitHub APIs, then check
positive merge and negative push/open/update/manual/unmerged-close scenarios.
Do not claim a settings change or hosted execution without inspecting its result.
Route prod promotion to github-prod-merge-action. Preserve test evidence reuse
and OOT-11 signing gates; do not duplicate passed checks or bypass missing evidence.
