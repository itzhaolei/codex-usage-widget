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

Entpacken Sie die Datei und doppelklicken Sie auf `Install Quota Bubble.app`. Quota Bubble liest die lokalen Codex-Kontingentdaten des aktuellen Benutzerkontos und startet direkt ohne Einrichtungsdialog.
Die macOS-App ruft Kontingentdaten nativ in Swift ab. Benutzer benötigen weder Node.js, npm, eine separat installierte Codex CLI, Xcode noch Befehlszeilentools, sondern nur macOS 13 oder neuer, eine angemeldete Codex-Installation mit `~/.codex/auth.json` und Netzwerkzugriff auf Codex.

Windows ist jetzt wie macOS auf v3.0.5. Laden Sie `QuotaBubble-*-Windows-Setup.exe` von der [neuesten Release-Seite](https://github.com/itzhaolei/codex-usage-widget/releases/latest) herunter und starten Sie den grafischen Installer per Doppelklick. PowerShell, Node.js, die Befehlszeile und eine separate .NET-Laufzeit werden nicht benötigt.

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

Dieses Plugin läuft lokal. Die macOS-App liest den aktuellen Codex-Token aus `~/.codex/auth.json` nur im Arbeitsspeicher, um Kontingent, Guthaben, Tarif und Reset-Credits dieses Kontos vom Codex-Backend abzurufen. Tokens werden nie in den Kontingent-Snapshot geschrieben; das Repository enthält keine persönlichen Zugangsdaten oder Kontodaten.
