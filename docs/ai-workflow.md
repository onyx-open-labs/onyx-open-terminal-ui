# AI Workflow

AI.md is the canonical shared policy. AGENTS.md is the instruction entry point
for tools that recognize that filename. Other tools must be explicitly given
AI.md; automatic recognition of AI.md is not assumed.

## Specialised Agents
Select agents/scaffold-reviewer.md when a structure review is needed.
Provide its full text with AI.md, the task, relevant files, and validation scope
to an available agent tool. Briefs are manually invoked and have no automatic
registration. A tool without delegation can follow the same brief itself.

## Skills
Skills live in .agents/skills/<skill-name>/SKILL.md. Folder names, YAML names and
Solution Explorer labels match. GitHub workflow skills use the `github-` prefix
and name the integration stage or PR check they own.

| Skill | Owns | Reuses / boundary |
| --- | --- | --- |
| [github-develop-merge-action](../.agents/skills/github-develop-merge-action/SKILL.md) | develop-build-test.yml: merged develop PRs, solution build/tests, NuGet Audit, Gitleaks, CodeQL | Local solution validation; no installer/release jobs |
| [github-test-merge-action](../.agents/skills/github-test-merge-action/SKILL.md) | test-beta.yml: develop-to-test promotion, shared packaging/smoke/release helpers, beta pre-releases | Local solution validation and tester procedures; no develop scans or PR event setup |
| [github-installer-pr-action](../.agents/skills/github-installer-pr-action/SKILL.md) | installer-smoke.yml: pre-merge/manual review checks and evidence | Shared installer helpers and release failure tests; no public publishing or develop scans |
| [dotnet-test-project](../.agents/skills/dotnet-test-project/SKILL.md) | .NET test-project/framework/discovery setup and local full-suite failure handling | Shared local solution validation; routes workflow changes to their stage owner |
| [repository-validation](../.agents/skills/repository-validation/SKILL.md) | Shared local solution validation and clean-diff checks | Canonical commands in AI.md; no workflow configuration |

Choose the workflow owner first; load a supporting skill only for work on its
responsibility. Keep reusable mechanics in build/ scripts and tester procedures
in deploy/ documentation. Update both callers when a shared helper contract changes.
Do not copy helper implementations or create parallel skills for the same workflow.

Some execution repeats are intentional: the test promotion validates its own merge
commit and actual candidate artifacts, while PR checks validate a review merge.
CodeQL needs a separate instrumented compilation for extraction. These checks
serve distinct requirements and do not justify duplicating their skill procedures.
No main/release-to-production workflow exists, so there is no placeholder main skill.

Tools supporting this discovery convention may expose the skills; otherwise read
the selected file explicitly and execute its instructions.
No automatic discovery or delegation was verified in an external agent runtime.
The manual fallback requires only file reading and a shell, and was exercised
during scaffold validation.

Add new briefs using purpose, responsibilities, scope, and validation sections.
Add skills using the same metadata and procedural format as the example.
Avoid duplicating root guidance. Add local AI.md files only for real additional
project constraints.
