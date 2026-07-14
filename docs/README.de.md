# Quota Bubble

[English](../README.md) | [中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [Nederlands](README.nl.md)

Ein schwebendes Fenster für macOS und Windows zum Anzeigen des Codex 5-Stunden-Limits, des Wochenlimits und verfügbarer Reset-Credits.

![Quota Bubble preview](../assets/preview-plus.png)

## Funktionen

- Zeigt Codex 5-Stunden-Nutzung, Wochennutzung und verfügbare Reset-Credits.
- Zeigt unter macOS die Ablaufdaten einzelner Reset-Credits mit einem roten Punkt innerhalb von drei Tagen und sonst mit einem grünen Punkt.
- Zeigt unter macOS das aktuelle Konto und das Ablaufdatum des Abonnements lokal an, ohne Anmeldedaten im Kontingent-Snapshot zu speichern.
- Hält Kontingentwerte beim Wechsel zwischen Live-Nutzung und lokalem Sitzungsprotokoll stabil.
- Läuft unabhängig und liest lokale Codex-Kontingentdaten.
- Speichert Fensterposition, Theme und Anheftstatus.
- Eine SwiftUI-App verwaltet HUD, Dock-Symbol, Menüs und Lebenszyklus gemeinsam.
- Bietet Menüaktionen für Updates, Deinstallation und Sprachwechsel.
- Zeigt einen kleinen roten Punkt neben der Versionsnummer, wenn auf GitHub eine neuere Version verfügbar ist.
- Unterstützt dunkles und helles Theme.
- Folgt automatisch der Systemsprache.

## Installation

### Methode 1: App-Installer

Wenn Sie Terminal nicht verwenden möchten, öffnen Sie die neueste Release-Seite und laden Sie dort den Installer-Anhang herunter:

[Neueste Release-Seite öffnen](https://github.com/itzhaolei/codex-usage-widget/releases/latest)

Entpacken Sie die Datei und doppelklicken Sie auf `Install Quota Bubble.app`. Quota Bubble liest die lokalen Codex-Kontingentdaten des aktuellen Benutzerkontos. Wenn lokale Codex-CLI-Daten noch nicht verfügbar sind, zeigt das Widget ein Setup-Overlay für Installation und Anmeldung.

Windows bleibt vorerst auf v2.1.3. Laden Sie `QuotaBubble-*-Windows.zip` von der [Windows-v2.1.3-Release-Seite](https://github.com/itzhaolei/codex-usage-widget/releases/tag/v2.1.3) herunter, entpacken Sie es und führen Sie `windows/install.ps1` aus.

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
