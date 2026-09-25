# Quota Bubble

[English](../README.md) | [中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [Nederlands](README.nl.md)

共通の Flutter/Dart コードで動作し、Codex の 5 時間クォータ、週間クォータ、リセット時刻、残高、プラン、アカウント、リセット回数を表示する macOS / Windows 対応のフローティングウィンドウです。

![Quota Bubble 4.0 preview](../assets/preview-v4.png?raw=1&v=20260926-4)

## 機能

- 5 時間制限がある場合は 5 時間クォータも表示し、週間クォータ、リセット時刻、残高、プラン、利用可能なリセット回数を表示。
- アカウントから返されたプランに応じて Free、Plus、Pro 5x/20x、Business、Business 5x/20x、Enterprise、Edu のバッジを表示。
- カウントダウンの後に、秒単位の正確な週間リセット日時と曜日をローカル時刻で表示。
- macOS のメニューバーと Windows のトレイツールチップでは、5 時間クォータがある場合はそれを優先し、ない場合は週間クォータの残量をリアルタイム表示。
- 閉じる操作ではウインドウを非表示にして描画を停止しますが、macOS メニューバーの割合または Windows トレイツールチップは更新を続けます。終了はメニューバーまたはトレイメニューから行います。
- macOS と Windows ではリセットごとの有効期限を表示し、3 日以内は赤、それ以外は緑の点で示します。
- macOS と Windows では現在のアカウントとサブスクリプション期限をローカル表示し、認証情報を使用量スナップショットへ保存しません。
- 利用可能なシステムストレージと物理メモリを表示し、Windows では C ドライブの空き容量を表示します。
- ライブクォータの値を安定させ、アカウント切り替え後に以前のアカウントのデータが表示されるのを防ぎます。
- ローカルの Codex 使用量データを読み取りながら独立して動作します。
- ウィンドウ位置、テーマ、最前面固定状態を保存。
- 共通の Flutter デスクトップコードが macOS と Windows の HUD、Dock またはトレイアイコン、メニュー、ライフサイクルを管理。
- アプリは 1 インスタンス、クォータウインドウは 1 つだけに制限し、非表示後はメニューバーまたはシステムトレイから再表示できます。
- Windows ではタスクバーの入口を維持し、macOS では最前面固定時にステータスバーのウインドウレベルを使用。
- 両プラットフォームで統一された macOS スタイルのベクターアイコンを使用。
- メニューバーまたはシステムトレイからアップデート、アンインストール、言語切り替えが可能。
- GitHub に新しいリリースがある場合、バージョン表示の横に小さな赤い点を表示。
- ダークモードとライトモードに対応。
- システム言語に自動追従。

## インストール

[Quota Bubble 公式サイト](https://htmlpreview.github.io/?https://github.com/itzhaolei/codex-usage-widget/blob/main/public/index.html?v=20260926-4)のメインボタンをクリックしてください。macOS / Windows を自動判定し、Release ページを経由せず最新の GUI インストーラーを直接ダウンロードします。

### macOS

macOS 13 以降。`macOS-Installer.zip` を解凍し、`Install Quota Bubble.app` を開きます。Node.js、npm、別途の Codex CLI、Xcode、コマンドラインツールは不要です。Codex にログインし、`~/.codex/auth.json` が作成されている必要があります。

### Windows

Windows 10 以降。`Windows-Setup.exe` を開いて GUI ウィザードに従います。インストール後、デスクトップに Quota Bubble の起動ショートカットが自動作成されます。PowerShell、Node.js、ターミナル操作、別途の .NET ランタイムは不要です。

## アンインストール

macOS はメニューバーの Quota Bubble メニューから **アンインストール**、Windows は **設定 > アプリ > インストールされているアプリ** を使用します。

## プライバシー

このプラグインはローカルで動作します。デスクトップアプリは `~/.codex/auth.json` の現在の Codex token をメモリ内でのみ読み取り、そのアカウントの使用量、残高、プラン、リセット回数を Codex バックエンドから取得します。Token はスナップショットへ書き込まれず、個人認証情報やアカウントデータもリポジトリに含まれません。
