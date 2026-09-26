# Quota Bubble

<table>
  <tr>
    <td width="72">
      <a href="https://htmlpreview.github.io/?https://github.com/itzhaolei/codex-usage-widget/blob/main/public/index.html?v=20260926-4"><img src="assets/app-icon.png?raw=1" width="56" alt="Quota Bubble app icon"></a>
    </td>
    <td>
      <strong>Official Website</strong><br>
      Detect your operating system and download the latest graphical installer directly.<br>
      <a href="https://htmlpreview.github.io/?https://github.com/itzhaolei/codex-usage-widget/blob/main/public/index.html?v=20260926-4"><strong>Open official website →</strong></a>
    </td>
  </tr>
</table>

[English](README.md) | [中文](docs/README.zh-CN.md) | [日本語](docs/README.ja.md) | [한국어](docs/README.ko.md) | [Deutsch](docs/README.de.md) | [Français](docs/README.fr.md) | [Español](docs/README.es.md) | [Português](docs/README.pt.md) | [Italiano](docs/README.it.md) | [Nederlands](docs/README.nl.md)

A compact Flutter desktop companion for watching current Codex usage limits on macOS and Windows without opening settings. It reads the signed-in account locally, requests the latest quota data from Codex, and keeps one shared Dart codebase across both platforms.

Website source lives in `public/` and is ready for Cloudflare Pages. Recommended Pages settings: project name `quota-bubble`, production branch `main`, build command `exit 0`, output directory `public`. Suggested free domain: `quotabubble.dpdns.org` after dpdns approval.

![Quota Bubble 4.0 dark-mode preview](assets/preview-v4.png?raw=1&v=20260926-4)

## Features

- Floating Codex quota HUD for macOS and Windows.
- Shows the 5-hour quota when present, weekly quota, reset timing, integer point balance, plan, and available reset credits.
- Displays Free, Plus, Pro 5x/20x, Business, Business 5x/20x, Enterprise, and Edu plan badges when reported by the account.
- Shows the exact weekly reset date and weekday in local time down to the second.
- Shows the live 5-hour quota percentage in the macOS menu bar and the Windows tray tooltip when present, otherwise the weekly quota percentage.
- Closing the window hides it and pauses window rendering, while the macOS menu-bar percentage or Windows tray tooltip continues to update; use the menu-bar or tray menu to quit.
- Lists reset-credit expiration dates with red and green urgency indicators on macOS and Windows.
- Shows the current account and subscription expiration locally on macOS and Windows without copying credentials into the quota snapshot.
- Shows available system storage and physical memory; Windows reports available C-drive space.
- Stabilizes live quota values and prevents data from a previous account appearing after an account switch.
- Runs independently of Codex Desktop and reads the signed-in account locally to request its quota data.
- Remembers position, theme, and pinned state.
- Runs as one Flutter desktop app on macOS and Windows: the HUD, platform entry points, menus, and lifecycle share one process.
- Enforces one application instance and one quota window, which can be restored from the menu bar or system tray after it is hidden.
- Keeps the Windows taskbar entry available and uses the macOS status-bar window level when pinned.
- Uses one consistent set of macOS-style vector symbols on both platforms.
- Adds menu-bar and system-tray actions for updates, the official website and sharing, uninstall, and language switching.
- Shows a small red dot next to the version label when a newer GitHub release is available.
- Supports dark and light themes.
- Automatically follows the system language.

## Install

[Open the official website](https://htmlpreview.github.io/?https://github.com/itzhaolei/codex-usage-widget/blob/main/public/index.html?v=20260926-4) and click the main download button. The website detects macOS or Windows and downloads the latest matching graphical installer directly, without opening the GitHub Release page.

### macOS

Requires macOS 13 or later. Unzip the downloaded `macOS-Installer.zip`, then open `Install Quota Bubble.app`. It installs the universal Flutter app for Apple silicon and Intel in Applications, enables login startup, and launches it.

Quota Bubble reads the current Codex sign-in locally and requests that account's data through its shared Flutter/Dart service. End users do not need Node.js, npm, a separately installed Codex CLI, Xcode, or command-line tools. Codex must be signed in and have created `~/.codex/auth.json`.

### Windows

Requires Windows 10 or later. Open the downloaded `Windows-Setup.exe` and follow the graphical setup wizard. It installs the self-contained desktop app, always creates a desktop launch shortcut, can enable launch at sign-in, and opens Quota Bubble. PowerShell, Node.js, a terminal, a separate .NET runtime, and manual commands are not required.

## Uninstall

On macOS, open the Quota Bubble menu-bar menu, choose **Uninstall**, and confirm. On Windows, uninstall Quota Bubble from **Settings > Apps > Installed apps**.

## Git Workflow

This repository is intended to be managed with git. After each change, commit and push:

```bash
bash scripts/git-sync.sh "Describe the change"
```

The script stages changed files, creates a commit, and pushes to `origin`.

## Privacy

This plugin runs locally. The desktop app reads the current Codex auth token from `~/.codex/auth.json` into memory only to request that account's quota, balance, plan, and reset-credit data from the Codex backend. Tokens are never written to the quota snapshot, and no personal credentials or account data are included in this repository.
