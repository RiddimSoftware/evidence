## Implementation notes

Re-checked Linear issue EVI-1 before continuing. Linear still reports status `In Progress` / status type `started`, with `completedAt: null` and `canceledAt: null`, so the issue remains active.

Existing PR: https://github.com/RiddimSoftware/evidence/pull/31
Branch: `symphony/evi-1-define-pr-change-evidence-plan-and-manifest-cont`
Commit on PR: `ed064ad Define PR change evidence contracts`

No additional code changes were made in this resume. The PR still contains the implementation of the PR change evidence plan/manifest contracts, fixture-backed tests, and the empty `--github-token` handling fix.

## Verification evidence

Previous local verification on the PR branch:

- `swift build` exited 0.
- `swift test` exited 0: 80 tests executed, 2 node-dependent skips, 0 failures.
- `swift test --filter PRChangeEvidenceContractsTests` exited 0: 6 tests executed, 0 failures.

Resume checks performed:

- Linear `_fetch issue:EVI-1` returned status `In Progress`, status type `started`, `completedAt: null`, `canceledAt: null`.
- `gh auth status` confirmed the active GitHub CLI account is `riddim-developer-bot[bot]` via `GH_TOKEN`.
- `gh pr view 31 --json ...` returned PR state `OPEN`, label `autonomous`, merge state `BLOCKED`, review decision `REVIEW_REQUIRED`, and no latest reviews.
- `gh pr checks 31` still reports failed GitHub Actions checks: `Smoke-test on macOS`, `Validate action.yml manifest`, `actionlint (example + repo workflows)`, `build-and-test`, and `pr-build`.
- Direct check-run annotations for all failed jobs still report: `The job was not started because recent account payments have failed or your spending limit needs to be increased. Please check the 'Billing & plans' section in your settings`.
- `git status --short` briefly showed workflow files as modified, but `git diff`, `git diff --summary`, and `git diff --numstat` showed no actual changes; refreshing the index left only untracked `handoff.md`.

## Tradeoffs

No code fix is appropriate for the current failure state. The GitHub Actions jobs still did not start, so there is no compiler, test, actionlint, or workflow output to address in the branch.

## Blockers / follow-ups

Human action required: resolve the GitHub Actions billing/payment/spending-limit issue for the account or organization, then rerun the failed checks on PR #31.

After the billing gate is cleared, rerun PR checks. If any job then fails with real build/test/actionlint output, resume this branch and fix that concrete failure.
