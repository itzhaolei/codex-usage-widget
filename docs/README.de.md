# Quota Bubble

[English](../README.md) | [中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [Nederlands](README.nl.md)

Ein schwebendes macOS-Fenster zum Anzeigen des Codex 5-Stunden-Limits, des Wochenlimits und verfügbarer Reset-Credits.

![Quota Bubble preview](../assets/preview-plus.png)

## Funktionen

- Zeigt Codex 5-Stunden-Nutzung, Wochennutzung und verfügbare Reset-Credits.
- Läuft unabhängig und liest lokale Codex-Kontingentdaten.
- Speichert Fensterposition, Theme und Anheftstatus.
- Hält jeweils nur ein HUD und einen Dock-Launcher aktiv.
- Bietet Menüaktionen für Updates, Deinstallation und Sprachwechsel.
- Zeigt einen kleinen roten Punkt neben der Versionsnummer, wenn auf GitHub eine neuere Version verfügbar ist.
- Unterstützt dunkles und helles Theme.
- Folgt automatisch der Systemsprache.

## Installation

### Methode 1: App-Installer

Wenn Sie Terminal nicht verwenden möchten, öffnen Sie die neueste Release-Seite und laden Sie dort den Installer-Anhang herunter:

[Neueste Release-Seite öffnen](https://github.com/itzhaolei/codex-usage-widget/releases/latest)

Entpacken Sie die Datei und doppelklicken Sie auf `Install Quota Bubble.app`. Codex Desktop sollte bereits installiert und angemeldet sein.

Die README verweist immer auf die neueste Release-Seite. Für ältere Versionen öffnen Sie [alle Releases](https://github.com/itzhaolei/codex-usage-widget/releases) und laden den Installer auf der jeweiligen Versionsseite herunter.

### Methode 2: Einzeilige Installation

```bash
CODEX_USAGE_WIDGET_URL=https://github.com/itzhaolei/codex-usage-widget/archive/refs/heads/main.tar.gz bash -c "$(curl -fsSL https://raw.githubusercontent.com/itzhaolei/codex-usage-widget/main/scripts/bootstrap-install.sh)"
```

### Methode 3: Lokale Installation

```bash
bash scripts/install.sh
```

## Deinstallation

```bash
bash scripts/uninstall.sh
```

## Datenschutz

Dieses Plugin läuft lokal. Es liest lokale Codex-Sitzungsmetadaten und den aktuellen Codex token aus `~/.codex/auth.json`, um nur die Reset-Credits des jeweiligen Benutzers vom Codex-Backend abzurufen. Dieses Repository enthält keine persönlichen Zugangsdaten oder Kontodaten.
