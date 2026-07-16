# Quota Bubble

[English](../README.md) | [中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [Nederlands](README.nl.md)

Codex の週間クォータ、リセット時刻、残高、プラン、アカウント、リセット回数を表示する macOS / Windows 対応のネイティブウィンドウです。

![Quota Bubble preview](../assets/preview-v3.png)

## 機能

- Codex の週間クォータ、リセット時刻、残高、プラン、利用可能なリセット回数を表示。
- macOS ではリセットごとの有効期限を表示し、3 日以内は赤、それ以外は緑の点で示します。
- macOS では現在のアカウントとサブスクリプション期限をローカル表示し、認証情報を使用量スナップショットへ保存しません。
- ライブ使用量とローカルセッションログの切り替え時も値を安定させます。
- ローカルの Codex 使用量データを読み取りながら独立して動作します。
- ウィンドウ位置、テーマ、最前面固定状態を保存。
- 1 つの SwiftUI アプリが HUD、Dock アイコン、メニュー、ライフサイクルを管理。
- メニューからアップデート、アンインストール、言語切り替えが可能。
- GitHub に新しいリリースがある場合、バージョン表示の横に小さな赤い点を表示。
- ダークモードとライトモードに対応。
- システム言語に自動追従。

## インストール

[Quota Bubble 公式サイト](https://htmlpreview.github.io/?https://github.com/itzhaolei/codex-usage-widget/blob/main/public/index.html?v=20260716-3)のメインボタンをクリックしてください。macOS / Windows を自動判定し、Release ページを経由せず最新の GUI インストーラーを直接ダウンロードします。

### macOS

macOS 13 以降。`macOS-Installer.zip` を解凍し、`Install Quota Bubble.app` を開きます。Node.js、npm、別途の Codex CLI、Xcode、コマンドラインツールは不要です。Codex にログインし、`~/.codex/auth.json` が作成されている必要があります。

### Windows

Windows 10 以降。`Windows-Setup.exe` を開いて GUI ウィザードに従います。PowerShell、Node.js、ターミナル操作、別途の .NET ランタイムは不要です。

## アンインストール

macOS はアプリメニューの **Quota Bubble > アンインストール**、Windows は **設定 > アプリ > インストールされているアプリ** を使用します。

## プライバシー

このプラグインはローカルで動作します。macOS アプリは `~/.codex/auth.json` の現在の Codex token をメモリ内でのみ読み取り、そのアカウントの使用量、残高、プラン、リセット回数を Codex バックエンドから取得します。Token はスナップショットへ書き込まれず、個人認証情報やアカウントデータもリポジトリに含まれません。
