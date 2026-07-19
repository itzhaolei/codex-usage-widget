# Quota Bubble

[English](../README.md) | [中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [Nederlands](README.nl.md)

Une fenêtre native pour macOS et Windows affichant le quota hebdomadaire Codex, le reset, le solde, l’offre, le compte et les réinitialisations disponibles.

![Quota Bubble preview](../assets/preview-v3.png)

## Fonctionnalités

- Affiche le quota hebdomadaire Codex, le reset, le solde, l’offre et les réinitialisations disponibles.
- Affiche sous macOS la date d’expiration de chaque réinitialisation, avec un point rouge à moins de trois jours et vert au-delà.
- Affiche localement sous macOS le compte actuel et l’expiration de l’abonnement sans enregistrer les identifiants dans l’instantané de quota.
- Stabilise les quotas en direct et empêche l’affichage des données du compte précédent après un changement de compte.
- Fonctionne indépendamment et lit les données locales de quota Codex.
- Mémorise la position, le thème et l’état épinglé.
- Une seule app SwiftUI gère le HUD, l’icône du Dock, les menus et le cycle de vie.
- Ouvre plusieurs fenêtres synchronisées depuis le menu de l’app ou avec `Command-N`. Elles partagent le même quota en direct et mémorisent leur position séparément.
- Ajoute des actions de menu pour mettre à jour, désinstaller et changer de langue.
- Affiche un petit point rouge à côté de la version lorsqu’une nouvelle release GitHub est disponible.
- Prend en charge les thèmes clair et sombre.
- Suit automatiquement la langue du système.

## Installation

Ouvrez le [site officiel Quota Bubble](https://htmlpreview.github.io/?https://github.com/itzhaolei/codex-usage-widget/blob/main/public/index.html?v=20260719-1) et cliquez sur le bouton principal. Le site détecte macOS ou Windows et télécharge directement le dernier installateur graphique sans ouvrir la page Releases.

### macOS

macOS 13 ou ultérieur. Décompressez `macOS-Installer.zip`, puis ouvrez `Install Quota Bubble.app`. Node.js, npm, Codex CLI séparé, Xcode et commandes ne sont pas requis. Codex doit être connecté et avoir créé `~/.codex/auth.json`.

### Windows

Windows 10 ou ultérieur. Ouvrez `Windows-Setup.exe` et suivez l’assistant graphique. PowerShell, Node.js, terminal et runtime .NET séparé ne sont pas requis.

## Désinstallation

Sous macOS, utilisez **Quota Bubble > Désinstaller**. Sous Windows, utilisez **Paramètres > Applications > Applications installées**.

## Confidentialité

Ce plugin s’exécute localement. L’application macOS lit uniquement en mémoire le token Codex actuel dans `~/.codex/auth.json` afin de demander au backend le quota, le solde, l’offre et les réinitialisations de ce compte. Le token n’est jamais écrit dans l’instantané et aucun identifiant personnel ni donnée de compte n’est inclus dans ce dépôt.
