# Changelog

All notable changes to Codex Usage Widget are documented here.

## 1.0.1 - Unreleased

### Added

- Added a USD balance display synced from the current Codex usage endpoint with the rest of the snapshot.

### Changed

- Increased the widget height and redesigned the bottom area as two native refined cards, with balance on the left and available resets on the right.

### Fixed

- Fixed the local install script so reinstalling during development restarts both the Dock launcher and the floating widget instead of leaving old processes running.
- Stopped the LaunchAgent before local reinstall work starts so it cannot relaunch the widget while the binary is being rebuilt.

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
