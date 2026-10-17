---
name: github-pipeline-policy
description: Configure or verify approval enforcement, stage names and GitHub Actions triggers for the develop, test and prod pipelines. Use when changing workflow events, branch protections or pipeline skills.
---

# GitHub Pipeline Policy

Read AI.md pipeline approval policy before changing automation.
Inspect every workflow and live branch protection, including automatic CodeQL setup.
Require approved PR merges into develop/test/main, enforce rules for admins and
dismiss stale approvals. Do not add pre-merge, manual, scheduled or unrestricted
push runs. Reject stale required pre-merge checks that would deadlock merging.
Keep workflow names develop/test/prod; main is the prod Git branch.
Use closed PR events with merged guards; explain skipped unmerged-closure entries.
Pin all checkouts to the event merge commit. Preserve least-privilege permissions.
Route build/security work to github-develop-merge-action and installer/release
work to github-test-merge-action; keep helper validation after the approved merge.
Verify branch approval settings through authenticated GitHub APIs, then check
positive merge and negative push/open/update/manual/unmerged-close scenarios.
Do not claim a settings change or hosted execution without inspecting its result.
Keep prod documented as unconfigured until its behavior is separately specified.
