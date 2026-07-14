# Quota Bubble

[English](../README.md) | [中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [Nederlands](README.nl.md)

Una ventana flotante para macOS y Windows que muestra el uso de Codex en 5 horas, el uso semanal y los reinicios disponibles.

![Quota Bubble preview](../assets/preview-plus.png)

## Funciones

- Muestra el uso de Codex en 5 horas, el uso semanal y los reinicios disponibles.
- En macOS muestra la caducidad de cada reinicio, con un punto rojo si vence en tres días y verde en caso contrario.
- En macOS muestra localmente la cuenta actual y la caducidad de la suscripción sin guardar credenciales en la instantánea de cuota.
- Mantiene estables los valores al alternar entre el uso en vivo y el registro de sesión local.
- Se ejecuta de forma independiente y lee datos locales de cuota de Codex.
- Recuerda posición, tema y estado fijado.
- Una sola app SwiftUI gestiona el HUD, el icono del Dock, los menús y el ciclo de vida.
- Añade acciones de menú para actualizar, desinstalar y cambiar idioma.
- Muestra un pequeño punto rojo junto a la versión cuando hay una release más reciente en GitHub.
- Soporta tema claro y oscuro.
- Sigue automáticamente el idioma del sistema.

## Instalación

### Método 1: Instalador de app

Si no quieres usar Terminal, abre la página de la última release y descarga allí el instalador:

[Abrir la página de la última release](https://github.com/itzhaolei/codex-usage-widget/releases/latest)

Descomprímelo y haz doble clic en `Install Quota Bubble.app`. Quota Bubble lee los datos locales de cuota de Codex de la cuenta de usuario actual. Si los datos locales de Codex CLI aún no están disponibles, el widget muestra una capa de configuración para instalar Codex CLI e iniciar sesión.

Windows permanece por ahora en v2.1.3. Descarga `QuotaBubble-*-Windows.zip` desde la [release de Windows v2.1.3](https://github.com/itzhaolei/codex-usage-widget/releases/tag/v2.1.3), descomprímelo y ejecuta `windows/install.ps1`.

El README siempre enlaza a la última release. Para instalar una versión anterior, abre [todas las releases](https://github.com/itzhaolei/codex-usage-widget/releases) y descarga el instalador desde la página de esa versión.

### Método 2: Instalación en una línea

```bash
CODEX_USAGE_WIDGET_URL=https://github.com/itzhaolei/codex-usage-widget/archive/refs/heads/main.tar.gz bash -c "$(curl -fsSL https://raw.githubusercontent.com/itzhaolei/codex-usage-widget/main/scripts/bootstrap-install.sh)"
```

### Método 3: Instalación local

```bash
bash scripts/install.sh
```

## Desinstalar

```bash
bash scripts/uninstall.sh
```

## Privacidad

Este plugin se ejecuta localmente. Lee metadatos locales de sesiones de Codex y el token actual de Codex en `~/.codex/auth.json` solo para solicitar al backend de Codex los reinicios disponibles del usuario. Este repositorio no incluye credenciales personales ni datos de cuenta.
