# Quota Bubble

[English](../README.md) | [中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [Nederlands](README.nl.md)

Une fenêtre flottante issue d’une base Flutter/Dart commune à macOS et Windows, affichant le quota 5 heures Codex, le quota hebdomadaire, le reset, le solde, l’offre, le compte et les réinitialisations disponibles.

![Quota Bubble 4.0 preview](../assets/preview-v4.png?raw=1&v=20260926-4)

## Fonctionnalités

- Affiche le quota 5 heures lorsqu’il existe, ainsi que le quota hebdomadaire Codex, le reset, le solde, l’offre et les réinitialisations disponibles.
- Affiche un badge Free, Plus, Pro 5x/20x, Business, Business 5x/20x, Enterprise ou Edu selon l’offre signalée par le compte.
- Affiche après le compte à rebours la date exacte du reset hebdomadaire et le jour de la semaine en heure locale, à la seconde près.
- Affiche dans la barre des menus macOS et l’infobulle de la zone de notification Windows le pourcentage du quota 5 heures lorsqu’il existe, sinon celui du quota hebdomadaire.
- Fermer masque la fenêtre et suspend son rendu ; le pourcentage continue de s’actualiser dans la barre des menus macOS ou l’infobulle Windows. Utilisez le menu de la barre des menus ou de la zone de notification pour quitter.
- Affiche sous macOS et Windows la date d’expiration de chaque réinitialisation, avec un point rouge à moins de trois jours et vert au-delà.
- Affiche localement sous macOS et Windows le compte actuel et l’expiration de l’abonnement sans enregistrer les identifiants dans l’instantané de quota.
- Affiche le stockage système et la mémoire physique disponibles ; sous Windows, l’espace libre du lecteur C est indiqué.
- Stabilise les quotas en direct et empêche l’affichage des données du compte précédent après un changement de compte.
- Fonctionne indépendamment de Codex Desktop, lit la connexion locale et demande les données de quota actuelles au backend Codex.
- Mémorise la position, le thème et l’état épinglé.
- Une base Flutter commune gère le HUD, l’icône du Dock ou de la zone de notification, les menus et le cycle de vie sous macOS et Windows.
- Limite l’application à une seule instance et une seule fenêtre de quota, qui peut être restaurée depuis la barre des menus ou la zone de notification après avoir été masquée.
- Conserve l’entrée de la barre des tâches sous Windows et utilise le niveau de fenêtre de la barre d’état lorsqu’elle est épinglée sous macOS.
- Utilise les mêmes icônes vectorielles de style macOS sur les deux plateformes.
- Ajoute dans la barre des menus ou la zone de notification des actions pour mettre à jour, ouvrir le site officiel et partager, désinstaller et changer de langue.
- Affiche un petit point rouge à côté de la version lorsqu’une nouvelle release GitHub est disponible.
- Prend en charge les thèmes clair et sombre.
- Suit automatiquement la langue du système.

## Installation

Ouvrez le [site officiel Quota Bubble](https://htmlpreview.github.io/?https://github.com/itzhaolei/codex-usage-widget/blob/main/public/index.html?v=20260926-4) et cliquez sur le bouton principal. Le site détecte macOS ou Windows et télécharge directement le dernier installateur graphique sans ouvrir la page Releases.

### macOS

macOS 13 ou ultérieur. Décompressez `macOS-Installer.zip`, puis ouvrez `Install Quota Bubble.app`. Node.js, npm, Codex CLI séparé, Xcode et commandes ne sont pas requis. Codex doit être connecté et avoir créé `~/.codex/auth.json`.

### Windows

Windows 10 ou ultérieur. Ouvrez `Windows-Setup.exe` et suivez l’assistant graphique. Après l’installation, un raccourci Quota Bubble est créé automatiquement sur le bureau. PowerShell, Node.js, terminal et runtime .NET séparé ne sont pas requis.

## Désinstallation

Sous macOS, ouvrez le menu Quota Bubble dans la barre des menus et choisissez **Désinstaller**. Sous Windows, utilisez **Paramètres > Applications > Applications installées**.

## Confidentialité

Ce plugin s’exécute localement. L’application de bureau lit uniquement en mémoire le token Codex actuel dans `~/.codex/auth.json` afin de demander au backend le quota, le solde, l’offre et les réinitialisations de ce compte. Le token n’est jamais écrit dans l’instantané et aucun identifiant personnel ni donnée de compte n’est inclus dans ce dépôt.
