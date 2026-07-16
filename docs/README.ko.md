# Quota Bubble

[English](../README.md) | [中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [Nederlands](README.nl.md)

Codex 주간 할당량, 재설정 시간, 잔액, 플랜, 계정 및 재설정 횟수를 보여 주는 macOS 및 Windows 네이티브 플로팅 창입니다.

![Quota Bubble preview](../assets/preview-v3.png)

## 기능

- Codex 주간 할당량, 재설정 시간, 잔액, 플랜 및 사용 가능한 재설정 횟수 표시.
- macOS에서 재설정별 만료일을 표시하며 3일 이내는 빨간 점, 그 외에는 초록 점으로 구분합니다.
- macOS에서 현재 계정과 구독 만료일을 로컬로 표시하고 인증 정보는 사용량 스냅샷에 저장하지 않습니다.
- 실시간 사용량과 로컬 세션 로그 간 전환 시에도 할당량 값을 안정적으로 유지합니다.
- Codex 데스크톱 앱의 실행 및 종료에 맞춰 동작.
- 창 위치, 테마, 항상 위 상태 저장.
- 하나의 SwiftUI 앱이 HUD, Dock 아이콘, 메뉴와 수명 주기를 함께 관리합니다.
- 메뉴에서 업데이트, 제거, 언어 전환을 지원.
- GitHub에 새 릴리스가 있으면 버전 표시 옆에 작은 빨간 점을 표시.
- 다크 모드와 라이트 모드 지원.
- 시스템 언어 자동 적용.

## 설치

[Quota Bubble 공식 웹사이트](https://htmlpreview.github.io/?https://github.com/itzhaolei/codex-usage-widget/blob/main/public/index.html?v=20260716-1)의 기본 다운로드 버튼을 클릭하세요. macOS 또는 Windows를 감지해 Release 페이지를 거치지 않고 최신 GUI 설치 프로그램을 바로 다운로드합니다.

### macOS

macOS 13 이상. `macOS-Installer.zip`의 압축을 풀고 `Install Quota Bubble.app`을 여세요. Node.js, npm, 별도 Codex CLI, Xcode 또는 명령줄 도구가 필요 없습니다. Codex에 로그인되어 있고 `~/.codex/auth.json`이 생성되어 있어야 합니다.

### Windows

Windows 10 이상. `Windows-Setup.exe`를 열고 GUI 설치 마법사를 따르세요. PowerShell, Node.js, 터미널 명령 또는 별도 .NET 런타임이 필요 없습니다.

## 제거

macOS에서는 앱 메뉴의 **Quota Bubble > 제거**, Windows에서는 **설정 > 앱 > 설치된 앱**을 사용하세요.

## 개인 정보

이 플러그인은 로컬에서 실행됩니다. macOS 앱은 `~/.codex/auth.json`의 현재 Codex token을 메모리에서만 읽어 해당 계정의 할당량, 잔액, 요금제 및 재설정 횟수를 Codex 백엔드에 요청합니다. Token은 스냅샷에 기록되지 않으며 저장소에도 개인 인증 정보나 계정 데이터가 포함되지 않습니다.
