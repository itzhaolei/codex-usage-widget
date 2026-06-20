---
name: codex-usage-widget
description: Install, restart, stop, or inspect the local macOS Quota Bubble. Use when the user asks for a floating quota window, Codex usage HUD, reset-credit display, or wants to manage this plugin's widget.
---

# Quota Bubble

This plugin provides a local macOS floating widget for Codex quota visibility.

## What It Installs

- `~/.codex/usage-widget/UsageWidget.app`: the macOS floating HUD.
- `~/Applications/Quota Bubble.app`: a Dock-visible launcher app with the plugin icon.
- `~/.codex/scripts/codex-usage-snapshot.mjs`: reads Codex session usage and reset-credit information.
- `~/.codex/usage-widget/ensure-usage-widget.sh`: keeps one widget running while Codex desktop is running.
- `~/Library/LaunchAgents/com.codex.usage-widget.autostart.plist`: launches the ensure script every 10 seconds.

## Commands

Run commands from the plugin root.

Install or update:

```bash
bash scripts/install.sh
```

One-line install for other users is documented in `ONE_LINE_INSTALL.md`. It uses `scripts/bootstrap-install.sh` after the plugin is published as a downloadable archive.

By default, install also adds `Quota Bubble.app` to the Dock. To skip Dock pinning:

```bash
PIN_TO_DOCK=0 bash scripts/install.sh
```

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
- The Dock launcher can be clicked to restart/show the widget.
- Closing Codex does not close Quota Bubble.
- Only one widget instance is kept alive.
- The close button hides the widget for the current Codex run.
- The widget refreshes the visible countdown every second and refreshes the snapshot in the background.
- Reset-credit cache is scoped by Codex account ID when available.

## Notes For Codex

When installing, updating, restarting, or uninstalling, filesystem writes target `~/.codex`, `~/Library/LaunchAgents`, and `~/plugins`, so request escalation if the sandbox requires it.
