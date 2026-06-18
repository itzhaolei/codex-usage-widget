# Codex Usage Widget

A local macOS floating widget for watching Codex usage limits without opening settings.

![Codex Usage Widget preview](assets/preview.png)

## Features

- Floating quota HUD for Codex desktop.
- Shows 5-hour usage, weekly usage, and available reset credits.
- Follows the Codex desktop lifecycle.
- Remembers position, theme, and pinned state.
- Keeps only one HUD and one Dock launcher instance running.
- Includes a Dock launcher app.
- Supports dark and light themes.

## One-Line Install

```bash
CODEX_USAGE_WIDGET_URL=https://github.com/itzhaolei/codex-usage-widget/archive/refs/heads/main.tar.gz bash -c "$(curl -fsSL https://raw.githubusercontent.com/itzhaolei/codex-usage-widget/main/scripts/bootstrap-install.sh)"
```

## Local Install

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

## Privacy

This plugin runs locally. It reads Codex local session metadata and the current Codex auth token from `~/.codex/auth.json` only on the user's machine to request that user's reset-credit count from the Codex backend. No personal credentials or account data are included in this repository.
