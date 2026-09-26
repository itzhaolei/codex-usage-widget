# Quota Bubble

[English](../README.md) | [中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [Nederlands](README.nl.md)

一个由同一套 Flutter/Dart 代码驱动的 macOS 与 Windows 悬浮窗口，用来直接查看 Codex 5 小时配额、周配额、重置时间、余额、套餐、账号和可用重置次数。

![Quota Bubble 4.0 预览](../assets/preview-v4.png?raw=1&v=20260926-4)

## 功能

- 有 5 小时限制时显示 5 小时配额，同时显示 Codex 周配额、包含天数的重置倒计时、整数点数余额、套餐和可用重置次数。
- 根据账号返回的套餐显示 Free、Plus、Pro 5x/20x、Business、Business 5x/20x、Enterprise 或 Edu 徽标。
- 在倒计时后显示精确到秒的本地周重置日期和对应周几。
- 在 macOS 顶部菜单栏和 Windows 托盘悬停提示中优先实时显示 5 小时额度剩余百分比，没有 5 小时限制时显示周额度百分比。
- 点击关闭只隐藏窗口并暂停窗口渲染，macOS 菜单栏百分比或 Windows 托盘悬停提示会继续更新；需要退出时使用菜单栏或托盘菜单。
- 在 macOS 和 Windows 上逐条显示重置次数的到期日期，三天内到期显示红点，否则显示绿点。
- 在 macOS 和 Windows 上显示当前账号和订阅到期时间，账号凭据不会写入配额快照。
- 显示可用系统存储空间和物理内存；Windows 明确显示 C 盘可用空间。
- 保持实时配额数值稳定，并避免切换账号后显示上一个账号的数据。
- 可独立于 Codex Desktop 运行，读取本机登录状态并向 Codex 后端请求最新配额数据。
- 记住窗口位置、深浅色模式和置顶状态。
- 使用同一套 Flutter 桌面代码统一管理 macOS 和 Windows 的悬浮窗、Dock 或托盘图标、菜单和生命周期。
- 严格保持一个应用实例和一个配额窗口；隐藏后可从菜单栏或系统托盘恢复显示。
- Windows 始终保留任务栏入口；macOS 置顶时使用系统状态栏窗口层级。
- 两个平台统一使用 macOS 风格的矢量图标。
- 在菜单栏或系统托盘提供版本更新、打开官网与分享、卸载和语言切换。
- 当 GitHub 上有新版本时，在版本号旁显示小红点。
- 支持深色和浅色模式。
- 自动跟随系统语言。

## 安装

打开 [Quota Bubble 官网](https://htmlpreview.github.io/?https://github.com/itzhaolei/codex-usage-widget/blob/main/public/index.html?v=20260926-4)，点击主下载按钮。官网会自动识别 macOS 或 Windows，并直接下载对应的最新图形安装器，不再跳转 GitHub Release 页面。

### macOS

需要 macOS 13 或更高版本。解压下载的 `macOS-Installer.zip`，然后打开 `Install Quota Bubble.app`。安装器会把同时支持 Apple 芯片和 Intel 的 Flutter 应用放入“应用程序”，注册登录启动并打开工具。

普通用户不需要 Node.js、npm、单独安装 Codex CLI、Xcode 或命令行工具。Codex 需要已登录并已生成 `~/.codex/auth.json`。

### Windows

需要 Windows 10 或更高版本。打开下载的 `Windows-Setup.exe`，按图形安装向导完成安装；安装后桌面会自动创建 Quota Bubble 启动图标。用户不需要 PowerShell、Node.js、终端命令或额外安装 .NET 运行时。

## 卸载

macOS 打开菜单栏中的 Quota Bubble 菜单，选择 **卸载** 并确认；Windows 在 **设置 > 应用 > 已安装的应用** 中卸载 Quota Bubble。

## Git 管理

每次调整后提交并推送：

```bash
bash scripts/git-sync.sh "描述这次改动"
```

## 隐私

插件只在本机运行。桌面应用只会在内存中读取 `~/.codex/auth.json` 的当前 Codex token，用于向 Codex 后端请求该账号的配额、余额、套餐和重置次数。Token 不会写入配额快照，仓库中也不包含个人凭据或账号数据。
