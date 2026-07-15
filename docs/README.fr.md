# Quota Bubble

[English](../README.md) | [中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [Nederlands](README.nl.md)

Une fenêtre flottante pour macOS et Windows afin d’afficher l’usage Codex sur 5 heures, l’usage hebdomadaire et les réinitialisations disponibles.

![Quota Bubble preview](../assets/preview-plus.png)

## Fonctionnalités

- Affiche l’usage Codex sur 5 heures, l’usage hebdomadaire et les réinitialisations disponibles.
- Affiche sous macOS la date d’expiration de chaque réinitialisation, avec un point rouge à moins de trois jours et vert au-delà.
- Affiche localement sous macOS le compte actuel et l’expiration de l’abonnement sans enregistrer les identifiants dans l’instantané de quota.
- Stabilise les valeurs lors du basculement entre l’usage en direct et le journal de session local.
- Fonctionne indépendamment et lit les données locales de quota Codex.
- Mémorise la position, le thème et l’état épinglé.
- Une seule app SwiftUI gère le HUD, l’icône du Dock, les menus et le cycle de vie.
- Ajoute des actions de menu pour mettre à jour, désinstaller et changer de langue.
- Affiche un petit point rouge à côté de la version lorsqu’une nouvelle release GitHub est disponible.
- Prend en charge les thèmes clair et sombre.
- Suit automatiquement la langue du système.

## Installation

### Méthode 1 : installateur d’application

Si vous ne souhaitez pas utiliser Terminal, ouvrez la dernière page de release et téléchargez-y l’installateur :

[Ouvrir la dernière page de release](https://github.com/itzhaolei/codex-usage-widget/releases/latest)

Décompressez-le, puis double-cliquez sur `Install Quota Bubble.app`. Quota Bubble lit les données locales de quota Codex du compte utilisateur actuel et s'ouvre directement, sans écran de configuration.

Windows reste pour le moment en v2.1.3. Téléchargez `QuotaBubble-*-Windows.zip` depuis la [release Windows v2.1.3](https://github.com/itzhaolei/codex-usage-widget/releases/tag/v2.1.3), décompressez-le, puis lancez `windows/install.ps1`.

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
