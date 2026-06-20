# Codex Usage Widget

[English](README.md) | [中文](docs/README.zh-CN.md) | [日本語](docs/README.ja.md) | [한국어](docs/README.ko.md) | [Deutsch](docs/README.de.md) | [Français](docs/README.fr.md) | [Español](docs/README.es.md) | [Português](docs/README.pt.md) | [Italiano](docs/README.it.md) | [Nederlands](docs/README.nl.md)

A local macOS floating widget for watching Codex usage limits without opening settings.

![Codex Usage Widget preview](assets/preview.png)

## Features

- Floating quota HUD for Codex desktop.
- Shows 5-hour usage, weekly usage, and available reset credits.
- Follows the Codex desktop lifecycle.
- Remembers position, theme, and pinned state.
- Keeps only one HUD and one Dock launcher instance running.
- Includes a Dock launcher app.
- Adds menu-bar actions for updates, uninstall, and language switching.
- Shows a small red dot next to the version label when a newer GitHub release is available.
- Supports dark and light themes.
- Automatically follows the system language.

## Install

### Method 1: App Installer

For users who do not want to use Terminal, open the latest release page and download the installer asset:

[Open the latest release page](https://github.com/itzhaolei/codex-usage-widget/releases/latest)

Unzip it, then double-click `Install Codex Usage Widget.app`. The installer copies the prebuilt widget and Dock launcher, registers the background launch agent, adds the launcher to Dock, and opens the widget.

The README always links to the latest release page. To install an older version, open [all releases](https://github.com/itzhaolei/codex-usage-widget/releases) and download the installer from that version's page.

Codex Desktop should already be installed and signed in. After installation, the widget reads the local Codex quota data from the current user account.

### Method 2: One-Line Install

```bash
CODEX_USAGE_WIDGET_URL=https://github.com/itzhaolei/codex-usage-widget/archive/refs/heads/main.tar.gz bash -c "$(curl -fsSL https://raw.githubusercontent.com/itzhaolei/codex-usage-widget/main/scripts/bootstrap-install.sh)"
```

### Method 3: Local Install

```bash
bash scripts/install.sh
```

The installer builds:

- `~/.codex/usage-widget/UsageWidget.app`
- `~/Applications/Codex Usage Widget.app`
- `~/Library/LaunchAgents/com.codex.usage-widget.autostart.plist`

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
