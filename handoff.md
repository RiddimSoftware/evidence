## Implementation notes

Opened PR: https://github.com/RiddimSoftware/evidence/pull/34

Implemented `evidence capture-pr` for EVI-3 on branch `symphony/evi-3-resolve-pr-before-after-revisions-and-prepare-wo`.

Key changes:
- Added PR metadata resolution through a `GitHubCLIPullRequestMetadataProvider` adapter using `gh pr view`.
- Added `ResolvePullRequestComparison` and `PrepareComparisonWorktrees` use cases behind fakeable `PullRequestMetadataProviding` and `GitRepositoryPreparing` ports.
- Added a Git adapter that resolves refs, uses merge first-parent selection for merged PRs, and prepares deterministic Evidence-owned worktrees under `<output>/worktrees/before-<shortsha>` and `<output>/worktrees/after-<shortsha>`.
- Reused the upstream `PRChangeEvidenceManifest` contract and extended it with optional PR title/state/ref/worktree fields so the manifest records selected before/after SHAs plus PR URL, title, state, base/head refs and SHAs, and merge SHA when present.
- Updated CLI help, README, and `action.yml` so `capture-pr` is discoverable and skips config, Homebrew media tools, and simulator booting in the composite Action path.
- Fixed an environment-sensitive existing token precedence issue: an explicit empty `--github-token ""` now fails before falling back to `GITHUB_TOKEN`.

## Verification evidence

- `swift build` passed after the rebase and conflict resolution.
- `swift test` passed after the rebase: 93 tests, 2 skipped because `/usr/local/bin/node` is not present for Playwright integration tests.
- `actionlint Examples/workflows/*.yml .github/workflows/*.yml` passed.
- Rebased successfully onto latest `origin/main` after resolving one conflict in `Sources/EvidenceCLIKit/EvidenceCLI.swift`.
- Confirmed branch was clean before push and had 1 commit ahead of `origin/main`.
- Confirmed `gh auth status` active account was `riddim-developer-bot[bot]` before PR creation.

## Tradeoffs

- `capture-pr` writes build status as `skipped` in the manifest because EVI-3 only prepares revisions and worktrees; building, simulator execution, and capture are out of scope.
- The manifest uses the existing PR change evidence contract from `origin/main` instead of a separate EVI-3-specific schema, with optional fields added for the resolver metadata required by this issue.
- Worktree cleanup is conservative: Evidence only refreshes a matching path when its ownership marker exists and `git status --porcelain` is clean.

## Blockers / follow-ups

None for EVI-3. Later MVP slices can consume the prepared worktree paths from the manifest to build, run, and capture each revision.
