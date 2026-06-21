# Quota Bubble

[English](../README.md) | [中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [Nederlands](README.nl.md)

Een zwevend macOS-venster voor Codex-gebruik over 5 uur, weekgebruik en beschikbare resets.

![Quota Bubble preview](../assets/preview-plus.png)

## Functies

- Toont Codex-gebruik over 5 uur, weekgebruik en beschikbare resets.
- Draait zelfstandig en leest lokale Codex-quotagegevens.
- Onthoudt positie, thema en vastzetstatus.
- Houdt slechts één HUD en één Dock-launcher actief.
- Biedt menuacties voor bijwerken, verwijderen en taal wisselen.
- Toont een kleine rode stip naast de versie wanneer er een nieuwere GitHub-release beschikbaar is.
- Ondersteunt donker en licht thema.
- Volgt automatisch de systeemtaal.

## Installatie

### Methode 1: app-installer

Als je Terminal niet wilt gebruiken, open dan de nieuwste releasepagina en download daar de installer:

[Open de nieuwste releasepagina](https://github.com/itzhaolei/codex-usage-widget/releases/latest)

Pak het bestand uit en dubbelklik op `Install Quota Bubble.app`. Codex Desktop moet al geïnstalleerd zijn en aangemeld zijn.

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

Deze plugin draait lokaal. Hij leest lokale Codex-sessiemetadata en de huidige Codex token in `~/.codex/auth.json` alleen om de beschikbare resets van de gebruiker op te vragen bij de Codex-backend. Deze repository bevat geen persoonlijke inloggegevens of accountgegevens.
