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

## 隐私

插件只在本机运行。它会读取用户本机的 Codex 会话元数据和 `~/.codex/auth.json` 中的当前 Codex token，用于向 Codex 后端请求该用户自己的可用重置次数。仓库中不包含个人凭据或账号数据。
