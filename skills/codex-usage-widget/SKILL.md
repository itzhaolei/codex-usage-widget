---
name: codex-usage-widget
description: Install, restart, stop, or inspect the local macOS Quota Bubble. Use when the user asks for a floating quota window, Codex usage HUD, reset-credit display, or wants to manage this plugin's widget.
---

# Quota Bubble

This plugin provides a local macOS floating widget for Codex quota visibility.

## What It Installs

- `/Applications/Quota Bubble.app`: the single SwiftUI macOS app that owns the HUD, Dock icon, and menus.
- `~/.codex/scripts/codex-usage-snapshot.mjs`: reads Codex session usage and reset-credit information.
- `~/.codex/usage-widget/ensure-usage-widget.sh`: opens the single app when explicitly invoked.
- `~/Library/LaunchAgents/com.codex.usage-widget.autostart.plist`: opens the app once at user login.

## Commands

Run commands from the plugin root.

Install or update:

```bash
bash scripts/install.sh
```

One-line install for other users is documented in `ONE_LINE_INSTALL.md`. It uses `scripts/bootstrap-install.sh` after the plugin is published as a downloadable archive.

Install also adds `Quota Bubble.app` to the Dock and removes duplicate legacy entries.

Restart the widget:

```bash
bash scripts/restart.sh
```

Stop the widget and unload the LaunchAgent:

```bash
bash scripts/uninstall.sh
```

Check status:

```bash
bash scripts/status.sh
```

## Behavior

- The widget can run independently of the Codex desktop app lifecycle.
- The Dock app can be clicked to activate the same running HUD process.
- Closing Codex does not close Quota Bubble.
- Only one widget instance is kept alive.
- The close button terminates the app, so its Dock running state clears immediately.
- The widget refreshes the visible countdown every second and refreshes the snapshot in the background.
- Reset-credit cache is scoped by Codex account ID when available.

## Notes For Codex

When installing, updating, restarting, or uninstalling, filesystem writes target `~/.codex`, `~/Library/LaunchAgents`, and `~/plugins`, so request escalation if the sandbox requires it.
