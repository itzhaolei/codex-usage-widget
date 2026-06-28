# Quota Bubble

[English](../README.md) | [中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [Nederlands](README.nl.md)

Une fenêtre flottante macOS pour afficher l’usage Codex sur 5 heures, l’usage hebdomadaire et les réinitialisations disponibles.

![Quota Bubble preview](../assets/preview-plus.png)

## Fonctionnalités

- Affiche l’usage Codex sur 5 heures, l’usage hebdomadaire et les réinitialisations disponibles.
- Fonctionne indépendamment et lit les données locales de quota Codex.
- Mémorise la position, le thème et l’état épinglé.
- Conserve un seul HUD et un seul lanceur Dock.
- Ajoute des actions de menu pour mettre à jour, désinstaller et changer de langue.
- Affiche un petit point rouge à côté de la version lorsqu’une nouvelle release GitHub est disponible.
- Prend en charge les thèmes clair et sombre.
- Suit automatiquement la langue du système.

## Installation

### Méthode 1 : installateur d’application

Si vous ne souhaitez pas utiliser Terminal, ouvrez la dernière page de release et téléchargez-y l’installateur :

[Ouvrir la dernière page de release](https://github.com/itzhaolei/codex-usage-widget/releases/latest)

Décompressez-le, puis double-cliquez sur `Install Quota Bubble.app`. Quota Bubble lit les données locales de quota Codex du compte utilisateur actuel. Si les données locales de Codex CLI ne sont pas encore disponibles, le widget affiche un écran de configuration pour installer Codex CLI et se connecter.

Le README pointe toujours vers la dernière page de release. Pour installer une ancienne version, ouvrez [toutes les releases](https://github.com/itzhaolei/codex-usage-widget/releases) et téléchargez l’installateur depuis la page de cette version.

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
