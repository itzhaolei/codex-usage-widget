# Codex Usage Widget

[English](../README.md) | [中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [Nederlands](README.nl.md)

Une fenêtre flottante macOS pour afficher l’usage Codex sur 5 heures, l’usage hebdomadaire et les réinitialisations disponibles.

![Codex Usage Widget preview](../assets/preview.png)

## Fonctionnalités

- Affiche l’usage Codex sur 5 heures, l’usage hebdomadaire et les réinitialisations disponibles.
- Suit le cycle de vie de l’application Codex Desktop.
- Mémorise la position, le thème et l’état épinglé.
- Conserve un seul HUD et un seul lanceur Dock.
- Prend en charge les thèmes clair et sombre.
- Suit automatiquement la langue du système.

## Installation

### Méthode 1 : installateur d’application

Si vous ne souhaitez pas utiliser Terminal, téléchargez l’installateur depuis la page des releases :

[Télécharger CodexUsageWidget-1.0.0-Installer.zip](https://github.com/itzhaolei/codex-usage-widget/releases/download/v1.0.0/CodexUsageWidget-1.0.0-Installer.zip)

Décompressez-le, puis double-cliquez sur `Install Codex Usage Widget.app`. Codex Desktop doit déjà être installé et connecté.

### Méthode 2 : installation en une ligne

```bash
CODEX_USAGE_WIDGET_URL=https://github.com/itzhaolei/codex-usage-widget/archive/refs/heads/main.tar.gz bash -c "$(curl -fsSL https://raw.githubusercontent.com/itzhaolei/codex-usage-widget/main/scripts/bootstrap-install.sh)"
```

### Méthode 3 : installation locale

```bash
bash scripts/install.sh
```

## Désinstallation

```bash
bash scripts/uninstall.sh
```

## Confidentialité

Ce plugin s’exécute localement. Il lit les métadonnées de session Codex locales et le token Codex actuel dans `~/.codex/auth.json` uniquement pour demander au backend Codex le nombre de réinitialisations disponibles de l’utilisateur. Aucun identifiant personnel ni donnée de compte n’est inclus dans ce dépôt.
