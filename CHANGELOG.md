# Changelog

All notable changes to Quota Bubble are documented here.

## Unreleased

### Added

- Added a localized New Window command with Command-N on macOS. Multiple windows run inside one app process and share the same live quota store while preserving separate window positions.

### Changed

- Updated the multilingual website for v3.0.8 with direct installer fallbacks, weekly recharge-animation details, refreshed cache-safe links, and a new production SwiftUI preview showing the current color palette and layout.
- Kept quota and account data synchronized across windows while making theme, pin state, progress color, position, and close controls independent per window.

### Fixed

- Changed the window close control to close only the window where it was clicked; the app exits only after the final window closes.

## 3.0.8 - 2026-07-18

### Added

- Added three 1080 x 1920 short-video campaign posters highlighting live quota visibility, local account isolation, and native Liquid Glass installation and updates.
- Added a coordinated weekly-quota recharge animation that begins at the previous real percentage and preserves the existing progress-bar appearance.
- Added five selectable progress colors with subtle moving star highlights and an orbiting color-card transition during a genuine quota reset.

### Fixed

- Prevented stale pre-reset snapshots from making the weekly quota alternate between old and newly reset values.
- Restricted recharge animation triggers to a real weekly reset for the same account, so account switching cannot play the reset animation.
- Correctly treats a single API usage window as the weekly quota when no separate secondary window is returned.
- Removed preview arguments, simulated percentages, and automatic debug animation playback from the production application.

## 3.0.7 - 2026-07-16

### Fixed

- Built the macOS release with Xcode 26.6 and verified native SwiftUI Glass symbols before upload, so macOS 26 users receive the intended clear Liquid Glass appearance instead of the compatibility blur fallback.

## 3.0.6 - 2026-07-16

### Added

- Added a localized Official Website item to the macOS application menu that opens the GitHub-hosted website preview.
- Added a localized Share item below Official Website that copies the website URL to the clipboard and confirms the action.
- Added operating-system detection to the website so macOS and Windows users download the matching latest graphical installer directly.
- Added a localized website sharing section with system sharing, link copying, privacy guidance, and platform-aware handoff messaging.

### Changed

- Removed the active background tint from the pin button; pinned state is now indicated only by the green pin icon.
- Redesigned the website around the current SwiftUI window, with a compact technical visual system and a real app-rendered preview.
- Replaced command-line installation guidance in the website and all ten README languages with a graphical website-first installation flow.
- Removed the horizontal green scan line from the website preview stage so it no longer cuts through the app window.
- Switched the macOS 26 light theme and metric cards to native clear Liquid Glass, with a translucent highlight edge and a low-opacity fallback for older systems.

## 3.0.5 - 2026-07-16

### Fixed

- Fixed the macOS updater fallback URL so GitHub API failures no longer produce a malformed array-style version and `bad range in URL` error.

## 3.0.4 - 2026-07-16

### Added

- Added a determinate progress bar and percentage to the macOS update window while the installer is downloading.
- Added a native Swift quota service for macOS that fetches usage, balance, plan, and reset-credit data inside the application.

### Fixed

- Automatically restarts the macOS application after an update installs successfully, using a detached helper that waits for the old process to exit before launching the new bundle.
- Displays the generic Codex `pro` plan as `Pro20x`, while preserving explicitly reported `Pro5x` plans.
- Removed the macOS runtime dependency on Node.js, npm, Codex CLI, and the external snapshot process while preserving account isolation and quota stabilization.

## 3.0.3 - 2026-07-16

### Added

- Added a compiled Windows desktop application built with .NET 8 and WPF, distributed as a self-contained graphical `Setup.exe`.
- Added a per-user Inno Setup installer with Start menu and optional desktop shortcuts, launch-at-sign-in, graphical uninstall, and in-app installer updates.
- Added a release-only compatibility bridge so existing v3.0.2 installations can automatically migrate from the old ZIP updater to the graphical installer without user command-line interaction.
- Added Windows CI coverage that compiles the application, launches the published executable, installs the graphical package, launches the installed application, and uninstalls it on a real Windows runner.

### Changed

- Moved Windows quota, account, plan, balance, reset-credit, and subscription parsing into the native application so end users no longer need PowerShell, Node.js, npm, a terminal, or a separately installed .NET runtime.
- Replaced the Windows script archive with `QuotaBubble-3.0.3-Windows-Setup.exe` and updated all ten README languages.
- Kept the fixed-width macOS-aligned widget, native tray menu, ten languages, one-second refresh, persistent theme/pin/position/language settings, and dynamic reset-expiration rows.

### Fixed

- Revalidates account identity after every quota response so a response from an account switched during an in-flight request cannot appear in the window.
- Debounces transient `auth.json` reads for three seconds while still clearing old quota immediately after a confirmed account change.
- Keeps quota fallback values only in memory and only for the same irreversible account fingerprint; tokens and account identifiers are never persisted by Quota Bubble.

## 3.0.2 - 2026-07-16

### Added

- Added a Windows v3.0.2 package aligned with the current macOS data model: weekly quota, reset-credit expiration rows, balance, available resets, account, subscription expiration, plan badges, and update status.
- Added ten-language Windows UI and tray language selection, dynamic window height, persisted theme/pin/position/language state, and in-app Windows updates.
- Added Windows PowerShell AST and WPF XAML validation on `windows-latest`, plus automated Release asset packaging.

### Changed

- Rebuilt the Windows WPF layout to match the current fixed-width Quota Bubble HUD and removed the obsolete Codex CLI setup overlay.
- Made the Windows version dynamic through packaged `VERSION` metadata and updated installation to replace old instances cleanly.

### Fixed

- Prevented unaffiliated session-log rate limits from replacing the current authenticated account's live quota when the usage endpoint briefly fails, eliminating cross-account jumps such as 100% to 22% and back.

## 3.0.1 - 2026-07-15

### Changed

- Removed the macOS prerequisite overlay and its Node.js/Codex CLI detection, installation, and login handoff actions. The widget now opens directly and keeps local quota synchronization independent of setup prompts.
- Changed the macOS installation target from the user-only Applications folder to `/Applications`, including administrator authorization when required, so Quota Bubble appears in Finder's standard Applications directory.
- Increased the macOS quota progress bar height by 15 points while keeping the window height fixed and consuming the existing bottom whitespace.
- Increased the macOS quota progress bar width by 45 points while keeping the percentage on the same row.

### Fixed

- Prevented the macOS language submenu from closing while hovered by isolating menu state from the quota store's one-second refresh cycle.
- Restored the Quota Bubble icon in Finder after installation by registering the `/Applications` bundle with Launch Services and providing complete bundle icon/version metadata.
- Kept both metric-card backgrounds equal in height, allowed titles to wrap to two lines, and expanded the window when either localized title needs the second line.
- Restored pin/unpin behavior by binding the window level directly to persisted `isPinned` state instead of relying on a global delegate callback from the button.
- Top-aligned both metric-card descriptions within a shared title area so one-line and two-line localized labels remain visually aligned.
- Replaced the nearly opaque macOS window tint with adaptive translucent glass: dark mode now uses deep glass and light mode uses bright glass while preserving the system blur behind the window.
- Added native interactive Liquid Glass on macOS 26 with theme-aware tinting, while retaining the adaptive `NSVisualEffectView` fallback for macOS 13 through 15.
- Kept release builds compatible with older Xcode SDKs by compiling the native Liquid Glass path only when that API is available to the compiler.
- Added immediate visual feedback to the pin control: pinned state uses a green filled pin and unpinned state uses a muted slashed pin, matching the already-applied window level.
- Reapplied the persisted pin level after SwiftUI/Liquid Glass finishes configuring the main window, and made pin-button changes update the main `NSWindow` directly so rendering helper surfaces cannot mask the real state.
- Kept both pinned and unpinned windows in their current macOS Space; pinned mode stays above windows there without following users into other desktops or full-screen apps.
- Made update checks resilient to GitHub API rate limits by falling back to the public latest-release redirect, and added download retries, HTTP failure detection, `ditto` extraction, process-launch error handling, and visible installer diagnostics.
- Removed the updater's dependency on Python for Dock maintenance, which could report a false update failure on clean Macs after the application had already been copied successfully.
- Prevented restarts from leaving a running App process without a window by using one explicit SwiftUI `Window` scene, quitting through the native app lifecycle before reopening, and relying on macOS `LSMultipleInstancesProhibited` instead of a stale-process-prone manual duplicate check.

## 3.0.0 - 2026-07-15

### Changed

- Rebuilt the macOS client as one native SwiftUI app whose floating window, Dock icon, menus, update flow, and lifecycle share one process.
- Split macOS quota models, local data synchronization, and presentation into focused modules while preserving the existing HUD layout and one-second refresh behavior.
- Simplified local installation, login startup, restart, status, uninstall, and installer packaging around the single `Quota Bubble.app` bundle.
- Aligned the quota row, progress bar, and reset-expiration list to the left edge of the metric cards.
- Changed the macOS release package to a Universal Binary for Apple Silicon and Intel Macs.
- Changed one-line installation to use the prebuilt release app, so end users no longer need Xcode Command Line Tools.

### Fixed

- Eliminated Dock launcher and HUD process state drift by removing the legacy two-app architecture.
- Added repeatable macOS model and build tests for plan badges, remaining percentages, countdown formatting, snapshot decoding, and SwiftUI compilation.
- Prevented account switches from combining a new account identity with a previous account's quota snapshot by validating a local redacted account fingerprint.
- Preserved the update progress and completion window while the installed app bundle is replaced.

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
