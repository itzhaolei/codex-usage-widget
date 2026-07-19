# Quota Bubble

[English](../README.md) | [中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [Nederlands](README.nl.md)

一个支持 macOS 和 Windows 的原生悬浮配额窗口，用来直接查看 Codex 周配额、重置时间、余额、套餐、账号和可用重置次数。

![Quota Bubble 预览](../assets/preview-v3.png)

## 功能

- 显示 Codex 周配额、重置时间、余额、套餐和可用重置次数。
- 在 macOS 上逐条显示重置次数的到期日期，三天内到期显示红点，否则显示绿点。
- 在 macOS 上显示当前账号和订阅到期时间，账号信息不会写入配额快照。
- 在实时接口与本地会话日志切换时保持配额数值稳定。
- 可独立运行，并读取本机 Codex 配额数据。
- 记住窗口位置、黑白模式和置顶状态。
- 使用单一 SwiftUI 应用统一管理悬浮窗、Dock 图标、菜单和生命周期。
- 可从应用菜单或按 `Command-N` 新建多个同步窗口；所有窗口共享同一份实时配额数据，并分别保存位置。
- 在菜单栏提供版本更新、卸载和语言切换。
- 当 GitHub 上有新版本时，在版本号旁显示小红点。
- 支持深色和浅色模式。
- 自动跟随系统语言。

## 安装

打开 [Quota Bubble 官网](https://htmlpreview.github.io/?https://github.com/itzhaolei/codex-usage-widget/blob/main/public/index.html?v=20260719-1)，点击主下载按钮。官网会自动识别 macOS 或 Windows，并直接下载对应的最新图形安装器，不再跳转 GitHub Release 页面。

### macOS

需要 macOS 13 或更高版本。解压下载的 `macOS-Installer.zip`，然后打开 `Install Quota Bubble.app`。安装器会把同时支持 Apple 芯片和 Intel 的 SwiftUI 应用放入“应用程序”和 Dock，注册登录启动并打开工具。

普通用户不需要 Node.js、npm、单独安装 Codex CLI、Xcode 或命令行工具。Codex 需要已登录并已生成 `~/.codex/auth.json`。

### Windows

需要 Windows 10 或更高版本。打开下载的 `Windows-Setup.exe`，按图形安装向导完成安装。用户不需要 PowerShell、Node.js、终端命令或额外安装 .NET 运行时。

## 卸载

macOS 在屏幕左上角选择 **Quota Bubble > 卸载** 并确认；Windows 在 **设置 > 应用 > 已安装的应用** 中卸载 Quota Bubble。

## Git 管理

每次调整后提交并推送：

```bash
bash scripts/git-sync.sh "描述这次改动"
```

## 隐私

插件只在本机运行。macOS 应用只会在内存中读取 `~/.codex/auth.json` 的当前 Codex token，用于向 Codex 后端请求该账号的配额、余额、套餐和重置次数。Token 不会写入配额快照，仓库中也不包含个人凭据或账号数据。
