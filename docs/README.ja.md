# Quota Bubble

[English](../README.md) | [中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [Nederlands](README.nl.md)

Codex の 5 時間使用量、週間使用量、利用可能なリセット回数を表示する macOS のフローティングウィンドウです。

![Quota Bubble preview](../assets/preview-plus.png)

## 機能

- Codex の 5 時間使用量、週間使用量、利用可能なリセット回数を表示。
- ローカルの Codex 使用量データを読み取りながら独立して動作します。
- ウィンドウ位置、テーマ、最前面固定状態を保存。
- フローティング HUD と Dock ランチャーをそれぞれ 1 つだけ維持。
- メニューからアップデート、アンインストール、言語切り替えが可能。
- GitHub に新しいリリースがある場合、バージョン表示の横に小さな赤い点を表示。
- ダークモードとライトモードに対応。
- システム言語に自動追従。

## インストール

### 方法 1：アプリインストーラー

Terminal を使いたくない場合は、最新の Release ページを開き、そこからインストーラーをダウンロードしてください。

[最新の Release ページを開く](https://github.com/itzhaolei/codex-usage-widget/releases/latest)

解凍して `Install Quota Bubble.app` をダブルクリックしてください。Codex Desktop は事前にインストールされ、ログイン済みである必要があります。

README は常に最新の Release ページにリンクしています。古いバージョンをインストールする場合は、[すべての Releases](https://github.com/itzhaolei/codex-usage-widget/releases) を開き、対象バージョンのページからインストーラーをダウンロードしてください。

### 方法 2：ワンラインインストール

```bash
CODEX_USAGE_WIDGET_URL=https://github.com/itzhaolei/codex-usage-widget/archive/refs/heads/main.tar.gz bash -c "$(curl -fsSL https://raw.githubusercontent.com/itzhaolei/codex-usage-widget/main/scripts/bootstrap-install.sh)"
```

### 方法 3：ローカルインストール

```bash
bash scripts/install.sh
```

## アンインストール

```bash
bash scripts/uninstall.sh
```

## プライバシー

このプラグインはローカルで動作します。Codex のローカルセッションメタデータと `~/.codex/auth.json` の現在の Codex token を、そのユーザー自身のリセット回数を取得するためにのみ使用します。個人認証情報やアカウントデータはこのリポジトリに含まれません。
