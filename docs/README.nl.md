# Quota Bubble

[English](../README.md) | [中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [Nederlands](README.nl.md)

Een zwevend venster uit één gedeelde Flutter/Dart-codebasis voor macOS en Windows, met Codex-5-uursquota, weekquota, resettijd, saldo, plan, account en beschikbare resets.

![Quota Bubble 4.0 preview](../assets/preview-v4.png?raw=1&v=20260926-4)

## Functies

- Toont het 5-uursquota wanneer dit bestaat, plus Codex-weekquota, resettijd, saldo, plan en beschikbare resets.
- Toont een badge voor Free, Plus, Pro 5x/20x, Business, Business 5x/20x, Enterprise of Edu op basis van het gemelde abonnement.
- Toont direct na het aftellen de exacte wekelijkse resettijd en weekdag in lokale tijd, tot op de seconde.
- Toont in de macOS-menubalk en de tooltip van het Windows-systeemvak eerst het 5-uursquotum als percentage wanneer dit bestaat, anders het weekquotum.
- Sluiten verbergt het venster en pauzeert de weergave; het percentage blijft bijgewerkt in de macOS-menubalk of Windows-tooltip. Sluit de app af via het menubalk- of systeemvakmenu.
- Toont op macOS en Windows de vervaldatum van elke reset, met een rode stip binnen drie dagen en anders een groene stip.
- Toont op macOS en Windows lokaal het huidige account en de vervaldatum van het abonnement zonder aanmeldgegevens in de quota-snapshot op te slaan.
- Toont beschikbare systeemopslag en fysiek geheugen; op Windows wordt de vrije ruimte op de C-schijf weergegeven.
- Houdt live quotawaarden stabiel en voorkomt dat na een accountwissel gegevens van het vorige account verschijnen.
- Draait zelfstandig en leest lokale Codex-quotagegevens.
- Onthoudt positie, thema en vastzetstatus.
- Eén gedeelde Flutter-codebasis beheert de HUD, het Dock- of systeemvakpictogram, menu's en de levenscyclus op macOS en Windows.
- Beperkt de app tot één instantie en één quotavenster, dat na verbergen via de menubalk of het systeemvak kan worden hersteld.
- Houdt de taakbalkingang op Windows beschikbaar en gebruikt op macOS bij vastzetten het vensterniveau van de statusbalk.
- Gebruikt op beide platforms dezelfde vectorpictogrammen in macOS-stijl.
- Biedt in de menubalk of het systeemvak acties voor bijwerken, verwijderen en taal wisselen.
- Toont een kleine rode stip naast de versie wanneer er een nieuwere GitHub-release beschikbaar is.
- Ondersteunt donker en licht thema.
- Volgt automatisch de systeemtaal.

## Installatie

Open de [officiële Quota Bubble-website](https://htmlpreview.github.io/?https://github.com/itzhaolei/codex-usage-widget/blob/main/public/index.html?v=20260926-4) en klik op de hoofdknop. De site detecteert macOS of Windows en downloadt de nieuwste grafische installer direct zonder de Release-pagina te openen.

### macOS

macOS 13 of nieuwer. Pak `macOS-Installer.zip` uit en open `Install Quota Bubble.app`. Node.js, npm, een aparte Codex CLI, Xcode en opdrachten zijn niet nodig. Codex moet zijn aangemeld en `~/.codex/auth.json` hebben gemaakt.

### Windows

Windows 10 of nieuwer. Open `Windows-Setup.exe` en volg de grafische wizard. Na de installatie wordt automatisch een Quota Bubble-snelkoppeling op het bureaublad gemaakt. PowerShell, Node.js, terminalopdrachten en een aparte .NET-runtime zijn niet nodig.

## Verwijderen

Open op macOS het Quota Bubble-menu in de menubalk en kies **Verwijderen**. Gebruik op Windows **Instellingen > Apps > Geïnstalleerde apps**.

## Privacy

Deze plugin draait lokaal. De desktop-app leest de huidige Codex-token uit `~/.codex/auth.json` alleen in het geheugen om quota, saldo, abonnement en resets voor dat account op te vragen. De token wordt nooit naar de snapshot geschreven en deze repository bevat geen persoonlijke inloggegevens of accountgegevens.
