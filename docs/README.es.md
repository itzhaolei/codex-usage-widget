# Quota Bubble

[English](../README.md) | [中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [Nederlands](README.nl.md)

Una ventana nativa para macOS y Windows que muestra la cuota semanal de Codex, reinicio, saldo, plan, cuenta y reinicios disponibles.

![Quota Bubble preview](../assets/preview-v3.png)

## Funciones

- Muestra la cuota semanal de Codex, el reinicio, el saldo, el plan y los reinicios disponibles.
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

Abre el [sitio oficial de Quota Bubble](https://htmlpreview.github.io/?https://github.com/itzhaolei/codex-usage-widget/blob/main/public/index.html?v=20260716-3) y pulsa el botón principal. Detecta macOS o Windows y descarga directamente el instalador gráfico más reciente sin abrir la página de Releases.

### macOS

Requiere macOS 13 o posterior. Descomprime `macOS-Installer.zip` y abre `Install Quota Bubble.app`. No requiere Node.js, npm, Codex CLI separado, Xcode ni comandos. Codex debe tener la sesión iniciada y haber creado `~/.codex/auth.json`.

### Windows

Requiere Windows 10 o posterior. Abre `Windows-Setup.exe` y sigue el asistente gráfico. No requiere PowerShell, Node.js, terminal ni un runtime .NET separado.

## Desinstalar

En macOS usa **Quota Bubble > Desinstalar**. En Windows usa **Configuración > Aplicaciones > Aplicaciones instaladas**.

## Privacidad

Este plugin se ejecuta localmente. La app de macOS lee en memoria el token actual de Codex desde `~/.codex/auth.json` solo para solicitar al backend la cuota, el saldo, el plan y los reinicios de esa cuenta. El token nunca se escribe en la instantánea y el repositorio no incluye credenciales personales ni datos de cuenta.
