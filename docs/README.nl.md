# Quota Bubble

[English](../README.md) | [中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [Nederlands](README.nl.md)

Een zwevend venster voor macOS en Windows voor Codex-gebruik over 5 uur, weekgebruik en beschikbare resets.

![Quota Bubble preview](../assets/preview-plus.png)

## Functies

- Toont Codex-gebruik over 5 uur, weekgebruik en beschikbare resets.
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

### Methode 1: app-installer

Als je Terminal niet wilt gebruiken, open dan de nieuwste releasepagina en download daar de installer:

[Open de nieuwste releasepagina](https://github.com/itzhaolei/codex-usage-widget/releases/latest)

Pak het bestand uit en dubbelklik op `Install Quota Bubble.app`. Quota Bubble leest lokale Codex-quotagegevens van het huidige gebruikersaccount en opent direct, zonder installatiescherm.
De macOS-app haalt quota native op met Swift. Gebruikers hebben geen Node.js, npm, afzonderlijk geïnstalleerde Codex CLI, Xcode of opdrachtregeltools nodig, alleen macOS 13 of nieuwer, een aangemelde Codex-installatie met `~/.codex/auth.json` en netwerktoegang tot Codex.

Windows is gelijkgetrokken met macOS op v3.0.3. Download `QuotaBubble-*-Windows-Setup.exe` via de [nieuwste release](https://github.com/itzhaolei/codex-usage-widget/releases/latest) en dubbelklik op het grafische installatieprogramma. PowerShell, Node.js, een terminal en een afzonderlijke .NET-runtime zijn niet nodig.

De README verwijst altijd naar de nieuwste releasepagina. Voor een oudere versie open je [alle releases](https://github.com/itzhaolei/codex-usage-widget/releases) en download je de installer vanaf de pagina van die versie.

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

Deze plugin draait lokaal. De macOS-app leest de huidige Codex-token uit `~/.codex/auth.json` alleen in het geheugen om quota, saldo, abonnement en resets voor dat account op te vragen. De token wordt nooit naar de snapshot geschreven en deze repository bevat geen persoonlijke inloggegevens of accountgegevens.
