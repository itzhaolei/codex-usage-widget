---
name: codex-usage-widget
description: Install, restart, uninstall, or inspect Quota Bubble. Use when the user asks for the Flutter Codex quota window, usage HUD, reset-credit display, or wants to manage this plugin's desktop installation.
---

# Quota Bubble

This plugin provides a Flutter desktop widget for local Codex quota visibility on macOS and Windows. The commands below manage the macOS installation; Windows users use the graphical installer from the official website.

## What It Installs

- `/Applications/Quota Bubble.app`: the single Flutter macOS app that owns the HUD, Dock icon, and menus.
- `~/.codex/usage-widget/ensure-usage-widget.sh`: opens the single app when explicitly invoked.
- `~/Library/LaunchAgents/com.codex.usage-widget.autostart.plist`: opens the app once at user login.

## Commands

Run commands from the plugin root.

Install or update:

```bash
bash scripts/install.sh
```

End users install from the official website, which detects macOS or Windows and directly downloads the latest graphical installer. Do not instruct end users to run terminal commands.

Install places `Quota Bubble.app` in Applications, enables login startup, and launches it.

Restart the widget:

```bash
bash scripts/restart.sh
```

Uninstall the widget and unload the LaunchAgent:

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
- The close button hides the window; use the menu-bar menu to quit the process.
- The widget refreshes visible countdown details every second. While hidden, it pauses window rendering and keeps the menu-bar quota percentage current.
- The shared Flutter/Dart application service fetches quota data locally.
- The installed app does not require Node.js, npm, Codex CLI, Xcode, or command-line tools at runtime.
- Quota stabilization and reset-credit caching are scoped to a redacted Codex account fingerprint.

## Notes For Codex

When installing, updating, restarting, or uninstalling, filesystem writes target `~/.codex`, `~/Library/LaunchAgents`, and `~/plugins`, so request escalation if the sandbox requires it.
