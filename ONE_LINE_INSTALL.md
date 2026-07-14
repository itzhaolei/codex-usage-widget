# One-Line Install

After publishing this plugin as a GitHub repository, users can install it with one command.

```bash
CODEX_USAGE_WIDGET_URL=https://github.com/itzhaolei/codex-usage-widget/archive/refs/heads/main.tar.gz bash -c "$(curl -fsSL https://raw.githubusercontent.com/itzhaolei/codex-usage-widget/main/scripts/bootstrap-install.sh)"
```

What the installer does:

- Downloads the plugin archive.
- Installs it to `~/plugins/codex-usage-widget`.
- Adds it to `~/.agents/plugins/marketplace.json`.
- Builds and installs one native SwiftUI macOS app for both the Dock icon and floating HUD.

For local testing from a checked-out plugin directory:

```bash
bash scripts/install.sh
```
