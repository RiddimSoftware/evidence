# Troubleshooting

## Xcode or Simulator Not Found

Run:

```sh
xcode-select -p
xcrun simctl list devices available
```

Install Xcode, open it once to finish setup, and select the active developer directory if needed:

```sh
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

## Missing ImageMagick

`resize` and `render-marketing` need `magick`. Install it when a workflow fails
with `Missing required tool 'magick'` or when marketing renders cannot produce a
PNG.

```sh
brew install imagemagick
magick --version
```

## Missing ffmpeg

`record-preview` needs `ffmpeg`. Raw `capture-pr` simulator video steps write
`.mov` files through `simctl`; use `ffmpeg` when a workflow later encodes those
movies into App Preview-compatible output.

```sh
brew install ffmpeg
ffmpeg -version
```

## Simulator Permissions

macOS may require screen recording or automation permissions for simulator capture workflows. If screenshots or recordings are blank, grant permissions to Terminal or your IDE in System Settings, then restart the simulator.

## Simulator Unavailable

`capture-pr`, `capture-screenshots`, and `capture-evidence` require an available
iOS simulator. List devices and runtimes before re-running:

```sh
xcrun simctl list devices available
xcrun simctl list runtimes
```

If the configured device name is not present, update the plan's
`ios.simulator`, set `ios.simulator_udid`, or install the matching simulator
runtime in Xcode.

## Old PR SHA No Longer Builds

`capture-pr` checks out and builds both selected revisions. If the before SHA is
old enough that it no longer builds with the current Xcode, dependency cache, or
signing setup, the command writes `manifest.json`, `report.md`, and build logs
under `<output>/logs/` before exiting non-zero. Re-run with explicit refs that
still represent the change:

```sh
evidence capture-pr \
  --repo ExampleOrg/ExampleApp \
  --pr 123 \
  --plan .evidence/pr-home.json \
  --output docs/build-evidence/pr-123 \
  --before-ref origin/main \
  --after-ref HEAD
```

Keep this as a debugging override. Pull request workflows should normally use
the event base and head SHAs supplied by GitHub.

## App Lacks XCTest Evidence Harness

`runner = "xctest"` plans require an app-side UI test target that reads
`EVIDENCE_PLAN_PATH`, `EVIDENCE_OUTPUT_DIR`, and `EVIDENCE_REVISION_ROLE`, then
runs the Evidence XCTest plan. Without that harness, `capture-pr` can build the
app but cannot perform arbitrary UI actions such as taps, text entry, swipes, or
accessibility waits.

Use `runner = "simctl"` for launch-only proof. The simctl runner supports only
launch, openURL, wait-by-seconds, screenshot, startVideo, and stopVideo steps.

## Missing GitHub Token

GitHub Actions PR comments require `github-token: ${{ secrets.GITHUB_TOKEN }}`
and `pull-requests: write` permission in the calling workflow. Without a token,
the Action can still run the capture and upload artifacts, but it skips the PR
comment step.

## No Artifacts Produced

If a workflow completes without screenshots or videos, inspect the resolved
output directory reported by the Action and the `capture-pr` report:

```sh
find docs/build-evidence -maxdepth 4 -type f
```

For `capture-pr`, look for `<output>/manifest.json`, `<output>/report.md`, and
`<output>/logs/`. Missing media usually means the plan failed before a capture
step, the output path points somewhere different than expected, or a simctl
runner plan used XCTest-only actions that need an app-side harness.

## Output Paths

Screenshot plans write to `EVIDENCE_OUTPUT_DIR`, then `APPSTORE_SCREENSHOT_DIR`, then `EvidenceOutput`.

CLI build evidence writes to `evidence_dir` from `.evidence.toml`, defaulting to `docs/build-evidence`.

## Config Validation

`.evidence.toml` requires:

```toml
scheme = "ExampleApp"
bundle_id = "com.example.app"
simulator_udid = "YOUR-SIMULATOR-UDID"
```

Validation errors name the field that needs attention. Keep app-specific bundle IDs, schemes, and generated artifacts in the consuming app repository.

## Nested Xcode Workspace Or Project

If `evidence capture-screenshots` runs from a directory above the Xcode workspace (for example, `.evidence.toml` lives at the repo root and the iOS project is in `ios/`), `xcodebuild` cannot find the scheme on its own and the run fails. Tell the CLI which workspace or project to use by setting one of:

```toml
xcode_workspace = "ios/MyApp.xcworkspace"
# or
xcode_project = "ios/MyApp.xcodeproj"
```

Set at most one of the two — `evidence` forwards the value to `xcodebuild` as `-workspace` or `-project`. Setting both is rejected at config-load time.
