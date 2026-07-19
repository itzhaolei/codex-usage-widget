# Quota Bubble

[English](../README.md) | [中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [Nederlands](README.nl.md)

Ein natives schwebendes Fenster für Codex-Wochenkontingent, Reset-Zeit, Guthaben, Tarif, Konto und Reset-Credits unter macOS und Windows.

![Quota Bubble preview](../assets/preview-v3.png)

## Funktionen

- Zeigt Codex-Wochenkontingent, Reset-Zeit, Guthaben, Tarif und verfügbare Reset-Credits.
- Zeigt unter macOS die Ablaufdaten einzelner Reset-Credits mit einem roten Punkt innerhalb von drei Tagen und sonst mit einem grünen Punkt.
- Zeigt unter macOS das aktuelle Konto und das Ablaufdatum des Abonnements lokal an, ohne Anmeldedaten im Kontingent-Snapshot zu speichern.
- Hält Kontingentwerte beim Wechsel zwischen Live-Nutzung und lokalem Sitzungsprotokoll stabil.
- Läuft unabhängig und liest lokale Codex-Kontingentdaten.
- Speichert Fensterposition, Theme und Anheftstatus.
- Eine SwiftUI-App verwaltet HUD, Dock-Symbol, Menüs und Lebenszyklus gemeinsam.
- Öffnet über das App-Menü oder `Command-N` mehrere synchronisierte Fenster. Alle teilen dieselben Live-Kontingentdaten und speichern ihre Position getrennt.
- Bietet Menüaktionen für Updates, Deinstallation und Sprachwechsel.
- Zeigt einen kleinen roten Punkt neben der Versionsnummer, wenn auf GitHub eine neuere Version verfügbar ist.
- Unterstützt dunkles und helles Theme.
- Folgt automatisch der Systemsprache.

## Installation

Öffnen Sie die [Quota Bubble-Website](https://htmlpreview.github.io/?https://github.com/itzhaolei/codex-usage-widget/blob/main/public/index.html?v=20260719-1) und klicken Sie auf den Hauptdownload. Die Website erkennt macOS oder Windows und lädt den passenden aktuellen grafischen Installer direkt, ohne Umweg über die Release-Seite.

### macOS

macOS 13 oder neuer. Entpacken Sie `macOS-Installer.zip` und öffnen Sie `Install Quota Bubble.app`. Node.js, npm, eine separate Codex CLI, Xcode und Befehlszeilentools sind nicht erforderlich. Codex muss angemeldet sein und `~/.codex/auth.json` erstellt haben.

### Windows

Windows 10 oder neuer. Öffnen Sie `Windows-Setup.exe` und folgen Sie dem grafischen Assistenten. PowerShell, Node.js, Terminalbefehle und eine separate .NET-Laufzeit sind nicht erforderlich.

## Deinstallation

Unter macOS wählen Sie **Quota Bubble > Deinstallieren** im App-Menü. Unter Windows verwenden Sie **Einstellungen > Apps > Installierte Apps**.

## Datenschutz

Dieses Plugin läuft lokal. Die macOS-App liest den aktuellen Codex-Token aus `~/.codex/auth.json` nur im Arbeitsspeicher, um Kontingent, Guthaben, Tarif und Reset-Credits dieses Kontos vom Codex-Backend abzurufen. Tokens werden nie in den Kontingent-Snapshot geschrieben; das Repository enthält keine persönlichen Zugangsdaten oder Kontodaten.
