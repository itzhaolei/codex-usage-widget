# Codex Usage Widget

[English](../README.md) | [中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [Nederlands](README.nl.md)

一个 macOS 悬浮配额窗口，用来直接查看 Codex 的 5 小时额度、每周额度和可用重置次数。

![Codex Usage Widget 预览](../assets/preview.png)

## 功能

- 显示 Codex 5 小时额度、每周额度和可用重置次数。
- 跟随 Codex 桌面端启动和关闭。
- 记住窗口位置、黑白模式和置顶状态。
- 只保留一个悬浮窗和一个 Dock 启动器实例。
- 支持深色和浅色模式。
- 自动跟随系统语言。

## 通过安装器安装

如果不想使用终端命令，可以直接从 Release 页面下载安装器：

[下载 CodexUsageWidget-1.0.0-Installer.zip](https://github.com/itzhaolei/codex-usage-widget/releases/download/v1.0.0/CodexUsageWidget-1.0.0-Installer.zip)

解压后，双击 `Install Codex Usage Widget.app` 即可安装。安装器会复制预编译好的悬浮窗和 Dock 启动器，注册后台自启动任务，把启动器放入 Dock，并打开工具。

使用前需要已经安装并登录 Codex Desktop。安装完成后，工具会读取当前用户本机的 Codex 配额数据并自动显示。

## 一行安装

```bash
CODEX_USAGE_WIDGET_URL=https://github.com/itzhaolei/codex-usage-widget/archive/refs/heads/main.tar.gz bash -c "$(curl -fsSL https://raw.githubusercontent.com/itzhaolei/codex-usage-widget/main/scripts/bootstrap-install.sh)"
```

## 本地安装

```bash
bash scripts/install.sh
```

## 卸载

```bash
bash scripts/uninstall.sh
```

## Git 管理

每次调整后提交并推送：

```bash
bash scripts/git-sync.sh "描述这次改动"
```

## 隐私

插件只在本机运行。它会读取用户本机的 Codex 会话元数据和 `~/.codex/auth.json` 中的当前 Codex token，用于向 Codex 后端请求该用户自己的可用重置次数。仓库中不包含个人凭据或账号数据。
