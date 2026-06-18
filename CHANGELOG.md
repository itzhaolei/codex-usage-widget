# Changelog

All notable changes to Codex Usage Widget are documented here.

## 1.0.0 - 2026-06-19

### Added

- Added a macOS floating quota HUD for Codex Desktop.
- Added 5-hour, weekly, and reset-credit quota display.
- Added once-per-second refresh with local snapshot updates.
- Added dark and light modes, pin/unpin, close controls, and saved window position.
- Added a Dock launcher app with a Codex icon and single-instance behavior.
- Added automatic lifecycle handling so the HUD follows the Codex app.
- Added Chinese, English, Japanese, Korean, German, French, Spanish, Portuguese, Italian, and Dutch documentation.
- Added one-line install support and GitHub release packaging.

### Fixed

- Fixed cold-start quota display when Codex has already exhausted the 5-hour quota and no new rate-limit event is emitted.
- Fixed Dock launcher state dropping while the HUD window was still open.
- Fixed duplicate widget instances.
- Fixed stale account data after switching accounts.
- Fixed reset-count display when the available reset count is zero.
- Fixed countdown formatting to avoid `0 seconds` and to use natural localized time text.
- Fixed quota percentage regressions where remaining usage could briefly increase because of older events.
- Fixed layout collapse when quota fields are missing.

### Notes

- The widget reads local Codex session metadata and local Codex auth tokens only to derive quota state and reset-credit availability.
- No personal account data is committed to this repository.
