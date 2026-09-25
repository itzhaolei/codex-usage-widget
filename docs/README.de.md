# Quota Bubble

[English](../README.md) | [中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [Nederlands](README.nl.md)

Ein schwebendes Fenster aus einer gemeinsamen Flutter/Dart-Codebasis für Codex-5-Stunden-Kontingent, Wochenkontingent, Reset-Zeit, Guthaben, Tarif, Konto und Reset-Credits unter macOS und Windows.

![Quota Bubble 4.0 preview](../assets/preview-v4.png?raw=1&v=20260926-4)

## Funktionen

- Zeigt bei vorhandenem 5-Stunden-Limit auch das 5-Stunden-Kontingent sowie Wochenkontingent, Reset-Zeit, Guthaben, Tarif und verfügbare Reset-Credits.
- Zeigt je nach gemeldetem Tarif ein Badge für Free, Plus, Pro 5x/20x, Business, Business 5x/20x, Enterprise oder Edu.
- Zeigt direkt nach dem Countdown den exakten wöchentlichen Reset-Zeitpunkt und Wochentag in lokaler Zeit bis zur Sekunde.
- Zeigt in der macOS-Menüleiste und im Windows-Tray-Tooltip vorrangig das 5-Stunden-Kontingent in Prozent, sonst das Wochenkontingent.
- Beim Schließen wird das Fenster ausgeblendet und nicht mehr gerendert; der Prozentwert in der macOS-Menüleiste oder im Windows-Tray-Tooltip wird weiter aktualisiert. Beenden erfolgt über das Menüleisten- oder Tray-Menü.
- Zeigt unter macOS und Windows die Ablaufdaten einzelner Reset-Credits mit einem roten Punkt innerhalb von drei Tagen und sonst mit einem grünen Punkt.
- Zeigt unter macOS und Windows das aktuelle Konto und das Ablaufdatum des Abonnements lokal an, ohne Anmeldedaten im Kontingent-Snapshot zu speichern.
- Zeigt verfügbaren Systemspeicher und physischen Arbeitsspeicher; unter Windows wird der freie Speicher auf Laufwerk C angezeigt.
- Hält Live-Kontingentwerte stabil und verhindert nach einem Kontowechsel die Anzeige von Daten des vorherigen Kontos.
- Läuft unabhängig und liest lokale Codex-Kontingentdaten.
- Speichert Fensterposition, Theme und Anheftstatus.
- Eine gemeinsame Flutter-Desktop-Codebasis verwaltet HUD, Dock- oder Tray-Symbol, Menüs und Lebenszyklus unter macOS und Windows.
- Beschränkt die App auf eine Instanz und ein Kontingentfenster, das nach dem Ausblenden über Menüleiste oder Infobereich wieder geöffnet werden kann.
- Behält unter Windows den Taskleisteneintrag bei und nutzt unter macOS im angehefteten Zustand die Statusleisten-Fensterebene.
- Verwendet auf beiden Plattformen einheitliche Vektorsymbole im macOS-Stil.
- Bietet in Menüleiste oder Infobereich Aktionen für Updates, Deinstallation und Sprachwechsel.
- Zeigt einen kleinen roten Punkt neben der Versionsnummer, wenn auf GitHub eine neuere Version verfügbar ist.
- Unterstützt dunkles und helles Theme.
- Folgt automatisch der Systemsprache.

## Installation

Öffnen Sie die [Quota Bubble-Website](https://htmlpreview.github.io/?https://github.com/itzhaolei/codex-usage-widget/blob/main/public/index.html?v=20260926-4) und klicken Sie auf den Hauptdownload. Die Website erkennt macOS oder Windows und lädt den passenden aktuellen grafischen Installer direkt, ohne Umweg über die Release-Seite.

### macOS

macOS 13 oder neuer. Entpacken Sie `macOS-Installer.zip` und öffnen Sie `Install Quota Bubble.app`. Node.js, npm, eine separate Codex CLI, Xcode und Befehlszeilentools sind nicht erforderlich. Codex muss angemeldet sein und `~/.codex/auth.json` erstellt haben.

### Windows

Windows 10 oder neuer. Öffnen Sie `Windows-Setup.exe` und folgen Sie dem grafischen Assistenten. Nach der Installation wird automatisch eine Quota-Bubble-Verknüpfung auf dem Desktop erstellt. PowerShell, Node.js, Terminalbefehle und eine separate .NET-Laufzeit sind nicht erforderlich.

## Deinstallation

Unter macOS öffnen Sie das Quota-Bubble-Menü in der Menüleiste und wählen **Deinstallieren**. Unter Windows verwenden Sie **Einstellungen > Apps > Installierte Apps**.

## Datenschutz

Dieses Plugin läuft lokal. Die Desktop-App liest den aktuellen Codex-Token aus `~/.codex/auth.json` nur im Arbeitsspeicher, um Kontingent, Guthaben, Tarif und Reset-Credits dieses Kontos vom Codex-Backend abzurufen. Tokens werden nie in den Kontingent-Snapshot geschrieben; das Repository enthält keine persönlichen Zugangsdaten oder Kontodaten.
