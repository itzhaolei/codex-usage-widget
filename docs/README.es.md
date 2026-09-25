# Quota Bubble

[English](../README.md) | [中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [Nederlands](README.nl.md)

Una ventana flotante creada con una base Flutter/Dart compartida para macOS y Windows que muestra la cuota de 5 horas de Codex, la cuota semanal, reinicio, saldo, plan, cuenta y reinicios disponibles.

![Quota Bubble 4.0 preview](../assets/preview-v4.png?raw=1&v=20260926-4)

## Funciones

- Muestra la cuota de 5 horas cuando existe, además de la cuota semanal de Codex, el reinicio, el saldo, el plan y los reinicios disponibles.
- Muestra una insignia Free, Plus, Pro 5x/20x, Business, Business 5x/20x, Enterprise o Edu según el plan informado por la cuenta.
- Muestra tras la cuenta atrás la fecha exacta del reinicio semanal y el día de la semana en hora local, con precisión de segundos.
- Muestra en la barra de menús de macOS y la información emergente de la bandeja de Windows el porcentaje de 5 horas cuando existe; si no, muestra el porcentaje semanal.
- Cerrar oculta la ventana y pausa su renderizado; el porcentaje sigue actualizándose en la barra de menús de macOS o la información emergente de Windows. Usa el menú de la barra o de la bandeja para salir.
- En macOS y Windows muestra la caducidad de cada reinicio, con un punto rojo si vence en tres días y verde en caso contrario.
- En macOS y Windows muestra localmente la cuenta actual y la caducidad de la suscripción sin guardar credenciales en la instantánea de cuota.
- Muestra el almacenamiento del sistema y la memoria física disponibles; en Windows indica el espacio libre de la unidad C.
- Mantiene estables los valores de cuota en vivo e impide mostrar datos de la cuenta anterior después de cambiar de cuenta.
- Se ejecuta de forma independiente y lee datos locales de cuota de Codex.
- Recuerda posición, tema y estado fijado.
- Una base Flutter compartida gestiona el HUD, el icono del Dock o la bandeja, los menús y el ciclo de vida en macOS y Windows.
- Limita la aplicación a una instancia y una ventana de cuota, que puede restaurarse desde la barra de menús o la bandeja del sistema después de ocultarla.
- Mantiene la entrada de la barra de tareas en Windows y usa el nivel de ventana de la barra de estado al fijarla en macOS.
- Usa el mismo conjunto de iconos vectoriales de estilo macOS en ambas plataformas.
- Añade acciones en la barra de menús o la bandeja del sistema para actualizar, desinstalar y cambiar idioma.
- Muestra un pequeño punto rojo junto a la versión cuando hay una release más reciente en GitHub.
- Soporta tema claro y oscuro.
- Sigue automáticamente el idioma del sistema.

## Instalación

Abre el [sitio oficial de Quota Bubble](https://htmlpreview.github.io/?https://github.com/itzhaolei/codex-usage-widget/blob/main/public/index.html?v=20260926-4) y pulsa el botón principal. Detecta macOS o Windows y descarga directamente el instalador gráfico más reciente sin abrir la página de Releases.

### macOS

Requiere macOS 13 o posterior. Descomprime `macOS-Installer.zip` y abre `Install Quota Bubble.app`. No requiere Node.js, npm, Codex CLI separado, Xcode ni comandos. Codex debe tener la sesión iniciada y haber creado `~/.codex/auth.json`.

### Windows

Requiere Windows 10 o posterior. Abre `Windows-Setup.exe` y sigue el asistente gráfico. Tras la instalación se crea automáticamente un acceso directo de Quota Bubble en el escritorio. No requiere PowerShell, Node.js, terminal ni un runtime .NET separado.

## Desinstalar

En macOS abre el menú Quota Bubble de la barra de menús y elige **Desinstalar**. En Windows usa **Configuración > Aplicaciones > Aplicaciones instaladas**.

## Privacidad

Este plugin se ejecuta localmente. La app de escritorio lee en memoria el token actual de Codex desde `~/.codex/auth.json` solo para solicitar al backend la cuota, el saldo, el plan y los reinicios de esa cuenta. El token nunca se escribe en la instantánea y el repositorio no incluye credenciales personales ni datos de cuenta.
