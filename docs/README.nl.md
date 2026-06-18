# Codex Usage Widget

[English](../README.md) | [中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [Nederlands](README.nl.md)

Een zwevend macOS-venster voor Codex-gebruik over 5 uur, weekgebruik en beschikbare resets.

![Codex Usage Widget preview](../assets/preview.png)

## Functies

- Toont Codex-gebruik over 5 uur, weekgebruik en beschikbare resets.
- Volgt de levenscyclus van Codex Desktop.
- Onthoudt positie, thema en vastzetstatus.
- Houdt slechts één HUD en één Dock-launcher actief.
- Ondersteunt donker en licht thema.
- Volgt automatisch de systeemtaal.

## Installatie

### Methode 1: app-installer

Als je Terminal niet wilt gebruiken, download dan de installer vanaf de releasepagina:

[Download CodexUsageWidget-1.0.0-Installer.zip](https://github.com/itzhaolei/codex-usage-widget/releases/download/v1.0.0/CodexUsageWidget-1.0.0-Installer.zip)

Pak het bestand uit en dubbelklik op `Install Codex Usage Widget.app`. Codex Desktop moet al geïnstalleerd zijn en aangemeld zijn.

### Methode 2: installatie met één opdracht

```bash
CODEX_USAGE_WIDGET_URL=https://github.com/itzhaolei/codex-usage-widget/archive/refs/heads/main.tar.gz bash -c "$(curl -fsSL https://raw.githubusercontent.com/itzhaolei/codex-usage-widget/main/scripts/bootstrap-install.sh)"
```

### Methode 3: lokale installatie

```bash
bash scripts/install.sh
```

## Verwijderen

```bash
bash scripts/uninstall.sh
```

## Privacy

Deze plugin draait lokaal. Hij leest lokale Codex-sessiemetadata en de huidige Codex token in `~/.codex/auth.json` alleen om de beschikbare resets van de gebruiker op te vragen bij de Codex-backend. Deze repository bevat geen persoonlijke inloggegevens of accountgegevens.
