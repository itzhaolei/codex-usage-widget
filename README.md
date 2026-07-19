# Quota Bubble

<table>
  <tr>
    <td width="72">
      <a href="https://htmlpreview.github.io/?https://github.com/itzhaolei/codex-usage-widget/blob/main/public/index.html?v=20260719-1"><img src="assets/app-icon.png?raw=1" width="56" alt="Quota Bubble app icon"></a>
    </td>
    <td>
      <strong>Official Website</strong><br>
      Detect your operating system and download the latest graphical installer directly.<br>
      <a href="https://htmlpreview.github.io/?https://github.com/itzhaolei/codex-usage-widget/blob/main/public/index.html?v=20260719-1"><strong>Open official website →</strong></a>
    </td>
  </tr>
</table>

[English](README.md) | [中文](docs/README.zh-CN.md) | [日本語](docs/README.ja.md) | [한국어](docs/README.ko.md) | [Deutsch](docs/README.de.md) | [Français](docs/README.fr.md) | [Español](docs/README.es.md) | [Português](docs/README.pt.md) | [Italiano](docs/README.it.md) | [Nederlands](docs/README.nl.md)

A local floating widget for watching Codex usage limits on macOS and Windows without opening settings.

Website source lives in `public/` and is ready for Cloudflare Pages. Recommended Pages settings: project name `quota-bubble`, production branch `main`, build command `exit 0`, output directory `public`. Suggested free domain: `quotabubble.dpdns.org` after dpdns approval.

![Quota Bubble preview](assets/preview-v3.png?raw=1)

## Features

- Floating quota HUD for Codex desktop.
- Shows weekly quota, reset timing, USD balance, plan, and available reset credits.
- Lists reset-credit expiration dates with red and green urgency indicators on macOS.
- Shows the current account and subscription expiration locally on macOS without copying credentials into the quota snapshot.
- Stabilizes live quota values and prevents data from a previous account appearing after an account switch.
- Runs independently while reading local Codex quota data.
- Remembers position, theme, and pinned state.
- Runs as one native SwiftUI macOS app: the HUD, Dock icon, menus, and lifecycle share one process.
- Opens multiple synchronized macOS windows from the app menu or with `Command-N`; every window shares the same live quota data while keeping its own position.
- Keeps a single Quota Bubble instance running and preserves the floating window position, theme, and pin state.
- Adds menu-bar actions for updates, uninstall, and language switching.
- Shows a small red dot next to the version label when a newer GitHub release is available.
- Supports dark and light themes.
- Automatically follows the system language.

## Install

[Open the official website](https://htmlpreview.github.io/?https://github.com/itzhaolei/codex-usage-widget/blob/main/public/index.html?v=20260719-1) and click the main download button. The website detects macOS or Windows and downloads the latest matching graphical installer directly, without opening the GitHub Release page.

### macOS

Requires macOS 13 or later. Unzip the downloaded `macOS-Installer.zip`, then open `Install Quota Bubble.app`. It installs the universal SwiftUI app for Apple silicon and Intel, adds it to Applications and Dock, enables login startup, and launches it.

Quota Bubble fetches data natively in Swift. End users do not need Node.js, npm, a separately installed Codex CLI, Xcode, or command-line tools. Codex must be signed in and have created `~/.codex/auth.json`.

### Windows

Requires Windows 10 or later. Open the downloaded `Windows-Setup.exe` and follow the graphical setup wizard. It installs the self-contained desktop app, creates shortcuts, can enable launch at sign-in, and opens Quota Bubble. PowerShell, Node.js, a terminal, a separate .NET runtime, and manual commands are not required.

## Uninstall

On macOS, choose **Quota Bubble > Uninstall** from the application menu and confirm. On Windows, uninstall Quota Bubble from **Settings > Apps > Installed apps**.

## Git Workflow

This repository is intended to be managed with git. After each change, commit and push:

```bash
bash scripts/git-sync.sh "Describe the change"
```

The script stages changed files, creates a commit, and pushes to `origin`.

## Privacy

This plugin runs locally. The macOS app reads the current Codex auth token from `~/.codex/auth.json` into memory only to request that account's quota, balance, plan, and reset-credit data from the Codex backend. Tokens are never written to the quota snapshot, and no personal credentials or account data are included in this repository.
