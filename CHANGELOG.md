# Changelog

All notable changes to Quota Bubble are documented here.

## Unreleased

### Changed

- Rebuilt the macOS client as one native SwiftUI app whose floating window, Dock icon, menus, update flow, and lifecycle share one process.
- Split macOS quota models, local data synchronization, and presentation into focused modules while preserving the existing HUD layout and one-second refresh behavior.
- Simplified local installation, login startup, restart, status, uninstall, and installer packaging around the single `Quota Bubble.app` bundle.

### Fixed

- Eliminated Dock launcher and HUD process state drift by removing the legacy two-app architecture.
- Added repeatable macOS model and build tests for plan badges, remaining percentages, countdown formatting, snapshot decoding, and SwiftUI compilation.

## 2.2.0 - 2026-07-14

### Added

- Added a macOS reset-credit expiration list with one row per available reset, using a red status dot for credits expiring within three days and green otherwise.
- Added current-account and subscription-expiration rows below the macOS metric cards, read directly from the current local Codex token without writing those values to the quota snapshot.

### Changed

- Replaced the second macOS quota progress row with the reset-credit expiration list and made the fixed-width window grow vertically with the list.
- Switched reset countdowns to compact unit formatting and omitted zero-value units.
- Refined vertical spacing around the progress bar, expiration list, metric cards, account, and subscription rows.

### Fixed

- Prevented transient empty snapshots from clearing the widget and added atomic snapshot writes.
- Corrected Pro20x subscription badge detection so it is not reported as Pro5x.
- Stabilized quota percentages and reset countdowns while switching between the live usage endpoint and session-log fallback data.
- Preserved account-specific quota state correctly while continuing to refresh after account changes.

### Notes

- Version 2.2.0 is released for macOS only. The latest Windows package remains v2.1.3.

## 2.1.3 - 2026-07-01

### Changed

- Changed the macOS first-run Node.js setup action from opening the download page to a direct install attempt with Homebrew when Homebrew is available, falling back to the Node.js download page otherwise.

## 2.1.2 - 2026-07-01

### Fixed

- Replaced the first-run `Unable to read snapshot` path error with the setup overlay when the local quota snapshot has not been generated yet.
- Added first-run detection for missing Node.js, with a download action instead of showing the raw snapshot path.
- Made Node.js detection compatible with shell-managed installs such as nvm while caching the check to avoid per-second process churn.

## 2.1.1 - 2026-06-29

### Fixed

- Removed the legacy `Install Codex Usage Widget.app` compatibility entry from the macOS installer zip so new users only see and launch `Install Quota Bubble.app`.
- Updated the macOS updater to select only `macOS-Installer.zip` release assets now that Windows packages are published alongside macOS packages.

## 2.1.0 - 2026-06-28

### Added

- Added a Windows PowerShell/WPF floating widget that mirrors the macOS quota layout, refreshes the shared snapshot every second, supports topmost mode, light/dark theme switching, tray controls, saved position, and Codex CLI install/login guidance.
- Added Windows install, uninstall, and release packaging scripts.
- Added Windows release packaging alongside the existing macOS installer.

### Changed

- Updated project metadata, README, and website copy from macOS-only wording to macOS and Windows support.

## 2.0.1 - 2026-06-28

### Added

- Added a first-run setup overlay that detects whether Codex CLI local data is available, guides users to install Codex CLI, and rechecks automatically after installation.
- Added an in-widget Codex CLI install and login handoff flow for machines that only have Codex Desktop data unavailable locally.

### Fixed

- Improved setup overlay button contrast so the install action stays readable on the dark translucent panel.

## 2.0.0 - 2026-06-21

### Changed

- Renamed the product from Codex Usage Widget to Quota Bubble across the floating window, Dock launcher, macOS app menu, installer, documentation, plugin metadata, and release assets.
- Replaced the Dock icon with a Quota Bubble branded `QB` icon.
- Updated the README preview image to use the Quota Bubble title.
- Restored the localized in-window title text, such as `Codex 额度` and `Codex Quota`, while keeping the app brand as Quota Bubble.
- Kept the underlying repository path, bundle identifiers, and local install directory compatible with existing 1.x installs.

### Added

- Added a static website in `public/` for Cloudflare Pages, with download, one-line install, feature, privacy, and deployment guidance sections.
- Added website language switching for Chinese, English, Japanese, Korean, German, French, Spanish, Portuguese, Italian, and Dutch.
- Added a website share button using the system share sheet with clipboard fallback.
- Added installer compatibility for 1.x updaters by including the legacy installer app entry in the 2.0.0 package.

### Fixed

- Cleans up old `Codex Usage Widget.app` Dock entries and app bundles when installing, updating, or uninstalling Quota Bubble.

## 1.1.0 - 2026-06-20

### Added

- Added a USD balance display synced from the current Codex usage endpoint with the rest of the snapshot.
- Added a red update indicator next to the version label when the installed version is older than the latest GitHub release.

### Changed

- Increased the widget height and redesigned the bottom area as two native refined cards, with balance on the left and available resets on the right.
- Raised the bottom cards slightly and replaced text-based card icons with cleaner system icons.
- Refined the bottom cards with centered text, compact sizing, theme-aware value colors, and a softer neumorphic style.
- Replaced text-block progress bar fill rendering with seamless drawing while keeping the original visual style, and added subtle 20% separators.

### Fixed

- Fixed the local install script so reinstalling during development restarts both the Dock launcher and the floating widget instead of leaving old processes running.
- Stopped the LaunchAgent before local reinstall work starts so it cannot relaunch the widget while the binary is being rebuilt.
- Aligned the subscription badge vertically with the title text.

### Notes

- The widget reads local Codex session metadata and local Codex auth tokens only to derive quota state, current usage limits, subscription type, USD balance, and reset-credit availability.
- Snapshot and cache files store only a short irreversible account fingerprint, not raw account IDs, email addresses, or tokens.

## 1.0.0 - 2026-06-19

### Added

- Added a macOS floating quota HUD for Codex Desktop.
- Added 5-hour, weekly, and reset-credit quota display.
- Added a small version label in the widget's bottom-right corner.
- Added menu-bar actions for checking updates, uninstalling with confirmation, and switching languages.
- Added once-per-second refresh with local snapshot updates.
- Added dark and light modes, pin/unpin, close controls, and saved window position.
- Added a Dock launcher app with a Codex icon and single-instance behavior.
- Added automatic lifecycle handling so the HUD follows the Codex app.
- Added Chinese, English, Japanese, Korean, German, French, Spanish, Portuguese, Italian, and Dutch documentation.
- Added one-line install support and GitHub release packaging.
- Added a downloadable macOS app installer on the release page for users who prefer not to use Terminal.

### Fixed

- Fixed cold-start quota display when Codex has already exhausted the 5-hour quota and no new rate-limit event is emitted.
- Fixed Dock launcher state dropping while the HUD window was still open.
- Fixed duplicate widget instances.
- Fixed stale account data after switching accounts.
- Fixed reset-count display when the available reset count is zero.
- Fixed countdown formatting to avoid `0 seconds` and to use natural localized time text.
- Fixed quota percentage regressions where remaining usage could briefly increase because of older events.
- Fixed layout collapse when quota fields are missing.
- Fixed installer-launched apps being translocated by macOS quarantine, which could make the background watcher repeatedly reopen the widget and briefly steal keyboard focus.
- Fixed README installation sections to clearly separate app installer, one-line command, and local install methods across all supported languages.
- Fixed README installer links to point to the latest release page instead of a version-specific installer asset.
- Fixed the update action so it does not reinstall when the installed version is already the latest release.
- Fixed the update status popup so it changes to success, already-latest, or failure instead of staying on the downloading state.
- Fixed HUD clicks so they activate the Dock launcher menu, matching the behavior of clicking the Dock icon.
- Fixed reset-time text rows to stay on one line and ellipsize when the text is too long.
- Fixed the title row so it stays clear of the control capsule and ellipsizes instead of wrapping.
- Fixed account switching so quota snapshots are keyed by a redacted local account fingerprint instead of raw account identifiers.
- Changed lifecycle handling so the widget no longer exits when Codex Desktop is closed.
- Fixed account switching so 5-hour and weekly quota rows stop reusing rate-limit events from the previous account.
- Fixed 5-hour and weekly quota refresh after account switches by reading Codex's current usage endpoint instead of relying on stale session rate-limit events.
- Added a non-compressing subscription badge after the widget title, showing Free, Plus, Pro5x, or Pro20x when available, with rounded backgrounds and white text.
- Updated the README preview image to show the current Pro20x badge UI.

### Notes

- The widget reads local Codex session metadata and local Codex auth tokens only to derive quota state, current usage limits, subscription type, and reset-credit availability.
- Snapshot and cache files store only a short irreversible account fingerprint, not raw account IDs, email addresses, or tokens.
- No personal account data is committed to this repository.
