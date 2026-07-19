# Quota Bubble

[English](../README.md) | [中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [Nederlands](README.nl.md)

Een native venster voor macOS en Windows met Codex-weekquota, resettijd, saldo, plan, account en beschikbare resets.

![Quota Bubble preview](../assets/preview-v3.png)

## Functies

- Toont Codex-weekquota, resettijd, saldo, plan en beschikbare resets.
- Toont op macOS de vervaldatum van elke reset, met een rode stip binnen drie dagen en anders een groene stip.
- Toont op macOS lokaal het huidige account en de vervaldatum van het abonnement zonder aanmeldgegevens in de quota-snapshot op te slaan.
- Houdt quotawaarden stabiel bij het wisselen tussen live gebruik en het lokale sessielogboek.
- Draait zelfstandig en leest lokale Codex-quotagegevens.
- Onthoudt positie, thema en vastzetstatus.
- Eén SwiftUI-app beheert de HUD, het Dock-pictogram, menu's en de levenscyclus.
- Biedt menuacties voor bijwerken, verwijderen en taal wisselen.
- Toont een kleine rode stip naast de versie wanneer er een nieuwere GitHub-release beschikbaar is.
- Ondersteunt donker en licht thema.
- Volgt automatisch de systeemtaal.

## Installatie

Open de [officiële Quota Bubble-website](https://htmlpreview.github.io/?https://github.com/itzhaolei/codex-usage-widget/blob/main/public/index.html?v=20260719-1) en klik op de hoofdknop. De site detecteert macOS of Windows en downloadt de nieuwste grafische installer direct zonder de Release-pagina te openen.

### macOS

macOS 13 of nieuwer. Pak `macOS-Installer.zip` uit en open `Install Quota Bubble.app`. Node.js, npm, een aparte Codex CLI, Xcode en opdrachten zijn niet nodig. Codex moet zijn aangemeld en `~/.codex/auth.json` hebben gemaakt.

### Windows

Windows 10 of nieuwer. Open `Windows-Setup.exe` en volg de grafische wizard. PowerShell, Node.js, terminalopdrachten en een aparte .NET-runtime zijn niet nodig.

## Verwijderen

Gebruik op macOS **Quota Bubble > Verwijderen**. Gebruik op Windows **Instellingen > Apps > Geïnstalleerde apps**.

## Privacy

Deze plugin draait lokaal. De macOS-app leest de huidige Codex-token uit `~/.codex/auth.json` alleen in het geheugen om quota, saldo, abonnement en resets voor dat account op te vragen. De token wordt nooit naar de snapshot geschreven en deze repository bevat geen persoonlijke inloggegevens of accountgegevens.
