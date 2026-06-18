# Codex Usage Widget

[English](../README.md) | [中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [Nederlands](README.nl.md)

Una ventana flotante para macOS que muestra el uso de Codex en 5 horas, el uso semanal y los reinicios disponibles.

![Codex Usage Widget preview](../assets/preview.png)

## Funciones

- Muestra el uso de Codex en 5 horas, el uso semanal y los reinicios disponibles.
- Sigue el ciclo de vida de la app Codex Desktop.
- Recuerda posición, tema y estado fijado.
- Mantiene solo un HUD y un lanzador de Dock.
- Soporta tema claro y oscuro.
- Sigue automáticamente el idioma del sistema.

## Instalación en una línea

```bash
CODEX_USAGE_WIDGET_URL=https://github.com/itzhaolei/codex-usage-widget/archive/refs/heads/main.tar.gz bash -c "$(curl -fsSL https://raw.githubusercontent.com/itzhaolei/codex-usage-widget/main/scripts/bootstrap-install.sh)"
```

## Instalación local

```bash
bash scripts/install.sh
```

## Desinstalar

```bash
bash scripts/uninstall.sh
```

## Privacidad

Este plugin se ejecuta localmente. Lee metadatos locales de sesiones de Codex y el token actual de Codex en `~/.codex/auth.json` solo para solicitar al backend de Codex los reinicios disponibles del usuario. Este repositorio no incluye credenciales personales ni datos de cuenta.
