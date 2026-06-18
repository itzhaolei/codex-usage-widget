# Codex Usage Widget

A local macOS floating widget for watching Codex usage limits without opening settings.

![Codex Usage Widget preview](assets/preview.png)

## Features

- Floating quota HUD for Codex desktop.
- Shows 5-hour usage, weekly usage, and available reset credits.
- Follows the Codex desktop lifecycle.
- Remembers position, theme, and pinned state.
- Keeps only one HUD and one Dock launcher instance running.
- Includes a Dock launcher app.
- Supports dark and light themes.
- Automatically follows the system language.

## Languages

The widget and Dock launcher support 10 languages:

- 中文
- English
- 日本語
- 한국어
- Deutsch
- Français
- Español
- Português
- Italiano
- Nederlands

## One-Line Install

```bash
CODEX_USAGE_WIDGET_URL=https://github.com/itzhaolei/codex-usage-widget/archive/refs/heads/main.tar.gz bash -c "$(curl -fsSL https://raw.githubusercontent.com/itzhaolei/codex-usage-widget/main/scripts/bootstrap-install.sh)"
```

## Multilingual Guide

### 中文

Codex Usage Widget 是一个 macOS 悬浮配额窗口，用来直接查看 Codex 的 5 小时额度、每周额度和可用重置次数。程序会自动读取系统语言。

安装：

```bash
CODEX_USAGE_WIDGET_URL=https://github.com/itzhaolei/codex-usage-widget/archive/refs/heads/main.tar.gz bash -c "$(curl -fsSL https://raw.githubusercontent.com/itzhaolei/codex-usage-widget/main/scripts/bootstrap-install.sh)"
```

### English

Codex Usage Widget is a macOS floating quota window for Codex 5-hour usage, weekly usage, and available reset credits. The app follows your system language automatically.

Install:

```bash
CODEX_USAGE_WIDGET_URL=https://github.com/itzhaolei/codex-usage-widget/archive/refs/heads/main.tar.gz bash -c "$(curl -fsSL https://raw.githubusercontent.com/itzhaolei/codex-usage-widget/main/scripts/bootstrap-install.sh)"
```

### 日本語

Codex Usage Widget は、Codex の 5 時間使用量、週間使用量、利用可能なリセット回数を表示する macOS のフローティングウィンドウです。アプリはシステム言語に自動で従います。

インストール：

```bash
CODEX_USAGE_WIDGET_URL=https://github.com/itzhaolei/codex-usage-widget/archive/refs/heads/main.tar.gz bash -c "$(curl -fsSL https://raw.githubusercontent.com/itzhaolei/codex-usage-widget/main/scripts/bootstrap-install.sh)"
```

### 한국어

Codex Usage Widget는 Codex의 5시간 사용량, 주간 사용량, 사용 가능한 재설정 횟수를 보여 주는 macOS 플로팅 창입니다. 앱은 시스템 언어를 자동으로 따릅니다.

설치:

```bash
CODEX_USAGE_WIDGET_URL=https://github.com/itzhaolei/codex-usage-widget/archive/refs/heads/main.tar.gz bash -c "$(curl -fsSL https://raw.githubusercontent.com/itzhaolei/codex-usage-widget/main/scripts/bootstrap-install.sh)"
```

### Deutsch

Codex Usage Widget ist ein schwebendes macOS-Fenster für das 5-Stunden-Limit, das Wochenlimit und verfügbare Reset-Credits von Codex. Die App folgt automatisch der Systemsprache.

Installation:

```bash
CODEX_USAGE_WIDGET_URL=https://github.com/itzhaolei/codex-usage-widget/archive/refs/heads/main.tar.gz bash -c "$(curl -fsSL https://raw.githubusercontent.com/itzhaolei/codex-usage-widget/main/scripts/bootstrap-install.sh)"
```

### Français

Codex Usage Widget est une fenêtre flottante macOS qui affiche l’usage Codex sur 5 heures, l’usage hebdomadaire et les réinitialisations disponibles. L’application suit automatiquement la langue du système.

Installation :

```bash
CODEX_USAGE_WIDGET_URL=https://github.com/itzhaolei/codex-usage-widget/archive/refs/heads/main.tar.gz bash -c "$(curl -fsSL https://raw.githubusercontent.com/itzhaolei/codex-usage-widget/main/scripts/bootstrap-install.sh)"
```

### Español

Codex Usage Widget es una ventana flotante para macOS que muestra el uso de Codex en 5 horas, el uso semanal y los reinicios disponibles. La app sigue automáticamente el idioma del sistema.

Instalación:

```bash
CODEX_USAGE_WIDGET_URL=https://github.com/itzhaolei/codex-usage-widget/archive/refs/heads/main.tar.gz bash -c "$(curl -fsSL https://raw.githubusercontent.com/itzhaolei/codex-usage-widget/main/scripts/bootstrap-install.sh)"
```

### Português

Codex Usage Widget é uma janela flutuante para macOS que mostra o uso de 5 horas, o uso semanal e as redefinições disponíveis do Codex. O app segue automaticamente o idioma do sistema.

Instalação:

```bash
CODEX_USAGE_WIDGET_URL=https://github.com/itzhaolei/codex-usage-widget/archive/refs/heads/main.tar.gz bash -c "$(curl -fsSL https://raw.githubusercontent.com/itzhaolei/codex-usage-widget/main/scripts/bootstrap-install.sh)"
```

### Italiano

Codex Usage Widget è una finestra flottante per macOS che mostra l’uso Codex su 5 ore, l’uso settimanale e i ripristini disponibili. L’app segue automaticamente la lingua di sistema.

Installazione:

```bash
CODEX_USAGE_WIDGET_URL=https://github.com/itzhaolei/codex-usage-widget/archive/refs/heads/main.tar.gz bash -c "$(curl -fsSL https://raw.githubusercontent.com/itzhaolei/codex-usage-widget/main/scripts/bootstrap-install.sh)"
```

### Nederlands

Codex Usage Widget is een zwevend macOS-venster voor Codex-gebruik over 5 uur, weekgebruik en beschikbare resets. De app volgt automatisch de systeemtaal.

Installatie:

```bash
CODEX_USAGE_WIDGET_URL=https://github.com/itzhaolei/codex-usage-widget/archive/refs/heads/main.tar.gz bash -c "$(curl -fsSL https://raw.githubusercontent.com/itzhaolei/codex-usage-widget/main/scripts/bootstrap-install.sh)"
```

## Local Install

```bash
bash scripts/install.sh
```

The installer builds:

- `~/.codex/usage-widget/UsageWidget.app`
- `~/Applications/Codex Usage Widget.app`
- `~/Library/LaunchAgents/com.codex.usage-widget.autostart.plist`

## Uninstall

```bash
bash scripts/uninstall.sh
```

## Privacy

This plugin runs locally. It reads Codex local session metadata and the current Codex auth token from `~/.codex/auth.json` only on the user's machine to request that user's reset-credit count from the Codex backend. No personal credentials or account data are included in this repository.
