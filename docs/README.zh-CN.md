# Codex Usage Widget

[English](../README.md) | [中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [Nederlands](README.nl.md)

一个 macOS 悬浮配额窗口，用来直接查看 Codex 的 5 小时额度、每周额度和可用重置次数。

![Codex Usage Widget 预览](../assets/preview.png)

## 功能

- 显示 Codex 5 小时额度、每周额度和可用重置次数。
- 跟随 Codex 桌面端启动和关闭。
- 记住窗口位置、黑白模式和置顶状态。
- 只保留一个悬浮窗和一个 Dock 启动器实例。
- 在菜单栏提供版本更新、卸载和语言切换。
- 当 GitHub 上有新版本时，在版本号旁显示小红点。
- 支持深色和浅色模式。
- 自动跟随系统语言。

## 安装

### 方式一：通过安装器安装

如果不想使用终端命令，可以打开最新版本发布页面，然后下载其中的安装器附件：

[打开最新版本发布页面](https://github.com/itzhaolei/codex-usage-widget/releases/latest)

解压后，双击 `Install Codex Usage Widget.app` 即可安装。安装器会复制预编译好的悬浮窗和 Dock 启动器，注册后台自启动任务，把启动器放入 Dock，并打开工具。

README 始终指向最新版本发布页。如果需要安装旧版本，请打开[所有版本页面](https://github.com/itzhaolei/codex-usage-widget/releases)，进入对应版本页面下载该版本的安装器。

使用前需要已经安装并登录 Codex Desktop。安装完成后，工具会读取当前用户本机的 Codex 配额数据并自动显示。

### 方式二：一行命令安装

```bash
CODEX_USAGE_WIDGET_URL=https://github.com/itzhaolei/codex-usage-widget/archive/refs/heads/main.tar.gz bash -c "$(curl -fsSL https://raw.githubusercontent.com/itzhaolei/codex-usage-widget/main/scripts/bootstrap-install.sh)"
```

### 方式三：本地安装

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
