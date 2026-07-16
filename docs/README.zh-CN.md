# Quota Bubble

[English](../README.md) | [中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [Nederlands](README.nl.md)

一个支持 macOS 和 Windows 的悬浮配额窗口，用来直接查看 Codex 的 5 小时额度、每周额度和可用重置次数。

![Quota Bubble 预览](../assets/preview-plus.png)

## 功能

- 显示 Codex 5 小时额度、每周额度和可用重置次数。
- 在 macOS 上逐条显示重置次数的到期日期，三天内到期显示红点，否则显示绿点。
- 在 macOS 上显示当前账号和订阅到期时间，账号信息不会写入配额快照。
- 在实时接口与本地会话日志切换时保持配额数值稳定。
- 可独立运行，并读取本机 Codex 配额数据。
- 记住窗口位置、黑白模式和置顶状态。
- 使用单一 SwiftUI 应用统一管理悬浮窗、Dock 图标、菜单和生命周期。
- 在菜单栏提供版本更新、卸载和语言切换。
- 当 GitHub 上有新版本时，在版本号旁显示小红点。
- 支持深色和浅色模式。
- 自动跟随系统语言。

## 安装

### 方式一：通过安装器安装

如果不想使用终端命令，可以打开最新版本发布页面，然后下载其中的安装器附件：

[打开最新版本发布页面](https://github.com/itzhaolei/codex-usage-widget/releases/latest)

解压后，双击 `Install Quota Bubble.app` 即可安装。安装器会复制预编译好的 SwiftUI 应用，注册登录自启动，把应用放入 Dock，并打开工具。

README 始终指向最新版本发布页。如果需要安装旧版本，请打开[所有版本页面](https://github.com/itzhaolei/codex-usage-widget/releases)，进入对应版本页面下载该版本的安装器。

工具会读取当前用户本机的 Codex 配额数据，并直接打开，不显示环境检查或安装引导遮罩。
macOS 应用使用 Swift 原生获取配额。普通用户不需要 Node.js、npm、单独安装的 Codex CLI、Xcode 或命令行工具；只需 macOS 13 或更高版本、已登录且已经生成 `~/.codex/auth.json` 的 Codex，以及能够访问 Codex 的网络。

Windows 已与 macOS 对齐到 v3.0.4。请从[最新版本发布页](https://github.com/itzhaolei/codex-usage-widget/releases/latest)下载 `QuotaBubble-*-Windows-Setup.exe`，双击后按照图形安装向导操作。用户不需要 PowerShell、Node.js、命令行或额外安装 .NET 运行时；更新和卸载也通过图形界面完成。

### 方式二：一行命令安装

```bash
CODEX_USAGE_WIDGET_URL=https://github.com/itzhaolei/codex-usage-widget/archive/refs/heads/main.tar.gz bash -c "$(curl -fsSL https://raw.githubusercontent.com/itzhaolei/codex-usage-widget/main/scripts/bootstrap-install.sh)"
```

该方式会安装最新 macOS Release 中的预编译应用，普通用户无需安装 Xcode Command Line Tools。

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

插件只在本机运行。macOS 应用只会在内存中读取 `~/.codex/auth.json` 的当前 Codex token，用于向 Codex 后端请求该账号的配额、余额、套餐和重置次数。Token 不会写入配额快照，仓库中也不包含个人凭据或账号数据。
