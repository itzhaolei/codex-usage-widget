# Quota Bubble

<table>
  <tr>
    <td width="72">
      <a href="https://htmlpreview.github.io/?https://github.com/itzhaolei/codex-usage-widget/blob/main/public/index.html?v=20260621-1"><img src="assets/app-icon.png?raw=1" width="56" alt="Quota Bubble app icon"></a>
    </td>
    <td>
      <strong>Official Website</strong><br>
      Download the installer, copy the one-line install command, and preview the multilingual product page.<br>
      <a href="https://htmlpreview.github.io/?https://github.com/itzhaolei/codex-usage-widget/blob/main/public/index.html?v=20260621-1"><strong>Open website preview →</strong></a>
    </td>
  </tr>
</table>

[English](README.md) | [中文](docs/README.zh-CN.md) | [日本語](docs/README.ja.md) | [한국어](docs/README.ko.md) | [Deutsch](docs/README.de.md) | [Français](docs/README.fr.md) | [Español](docs/README.es.md) | [Português](docs/README.pt.md) | [Italiano](docs/README.it.md) | [Nederlands](docs/README.nl.md)

A local floating widget for watching Codex usage limits on macOS and Windows without opening settings.

Website source lives in `public/` and is ready for Cloudflare Pages. Recommended Pages settings: project name `quota-bubble`, production branch `main`, build command `exit 0`, output directory `public`. Suggested free domain: `quotabubble.dpdns.org` after dpdns approval.

![Quota Bubble preview](assets/preview-plus.png?raw=1)

## Features

- Floating quota HUD for Codex desktop.
- Shows 5-hour usage, weekly usage, USD balance, and available reset credits.
- Runs independently while reading local Codex quota data.
- Remembers position, theme, and pinned state.
- Keeps only one HUD and one Dock launcher instance running.
- Includes a renamed Dock launcher app and refreshed Quota Bubble icon.
- Adds menu-bar actions for updates, uninstall, and language switching.
- Shows a small red dot next to the version label when a newer GitHub release is available.
- Supports dark and light themes.
- Automatically follows the system language.

## Install

### macOS

#### Method 1: App Installer

For users who do not want to use Terminal, open the latest release page and download the macOS installer asset named `QuotaBubble-*-macOS-Installer.zip`:

[Open the latest release page](https://github.com/itzhaolei/codex-usage-widget/releases/latest)

Unzip it, then double-click `Install Quota Bubble.app`. The installer copies the prebuilt widget and Dock launcher, registers the background launch agent, adds the launcher to Dock, and opens the widget.

The README always links to the latest release page. To install an older version, open [all releases](https://github.com/itzhaolei/codex-usage-widget/releases) and download the installer from that version's page.

Quota Bubble reads local Codex quota data from the current user account. If the local Codex CLI data is not available yet, the widget shows a setup overlay that can install Codex CLI and guide the user to log in.

If Node.js is missing on macOS, the widget now shows the same setup overlay and links to the Node.js download page instead of showing a raw missing snapshot path.

#### Method 2: One-Line Install

```bash
CODEX_USAGE_WIDGET_URL=https://github.com/itzhaolei/codex-usage-widget/archive/refs/heads/main.tar.gz bash -c "$(curl -fsSL https://raw.githubusercontent.com/itzhaolei/codex-usage-widget/main/scripts/bootstrap-install.sh)"
```

#### Method 3: Local Install

```bash
bash scripts/install.sh
```

The installer builds:

- `~/.codex/usage-widget/UsageWidget.app`
- `~/Applications/Quota Bubble.app`
- `~/Library/LaunchAgents/com.codex.usage-widget.autostart.plist`

### Windows

Open the latest release page and download the Windows package:

[Open the latest release page](https://github.com/itzhaolei/codex-usage-widget/releases/latest)

Unzip `QuotaBubble-*-Windows.zip`, then run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\windows\install.ps1
```

The Windows installer copies the widget to `%USERPROFILE%\.codex\usage-widget`, installs the shared snapshot script under `%USERPROFILE%\.codex\scripts`, creates a Startup shortcut, and opens the floating widget. It uses the same local snapshot logic as the macOS widget.

Windows requirements:

- Windows 10 or later.
- Node.js and npm available as `node` and `npm`.
- Codex CLI local data under `%USERPROFILE%\.codex`, or `CODEX_HOME` pointing to a compatible Codex data directory.

## Uninstall

```bash
bash scripts/uninstall.sh
```

## Git Workflow

This repository is intended to be managed with git. After each change, commit and push:

```bash
bash scripts/git-sync.sh "Describe the change"
```

The script stages changed files, creates a commit, and pushes to `origin`.

## Privacy

This plugin runs locally. It reads Codex local session metadata and the current Codex auth token from `~/.codex/auth.json` only on the user's machine to request that user's reset-credit count from the Codex backend. No personal credentials or account data are included in this repository.
