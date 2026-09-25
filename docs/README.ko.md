# Quota Bubble

[English](../README.md) | [中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [Nederlands](README.nl.md)

하나의 Flutter/Dart 코드로 macOS와 Windows에서 실행되며 Codex 5시간 할당량, 주간 할당량, 재설정 시간, 잔액, 플랜, 계정 및 재설정 횟수를 보여 주는 플로팅 창입니다.

![Quota Bubble 4.0 preview](../assets/preview-v4.png?raw=1&v=20260926-4)

## 기능

- 5시간 제한이 있으면 5시간 할당량도 표시하고, 주간 할당량, 재설정 시간, 잔액, 플랜 및 사용 가능한 재설정 횟수를 표시합니다.
- 계정에서 보고한 플랜에 따라 Free, Plus, Pro 5x/20x, Business, Business 5x/20x, Enterprise 또는 Edu 배지를 표시합니다.
- 카운트다운 뒤에 초 단위의 정확한 주간 재설정 날짜와 요일을 현지 시간으로 표시합니다.
- macOS 메뉴 막대와 Windows 트레이 도구 설명에는 5시간 할당량이 있으면 이를 우선 표시하고, 없으면 주간 할당량 비율을 실시간으로 표시합니다.
- 닫기 버튼은 창을 숨기고 렌더링을 일시 중지하지만 macOS 메뉴 막대 비율 또는 Windows 트레이 도구 설명은 계속 갱신됩니다. 종료는 메뉴 막대 또는 트레이 메뉴에서 실행합니다.
- macOS와 Windows에서 재설정별 만료일을 표시하며 3일 이내는 빨간 점, 그 외에는 초록 점으로 구분합니다.
- macOS와 Windows에서 현재 계정과 구독 만료일을 로컬로 표시하고 인증 정보는 사용량 스냅샷에 저장하지 않습니다.
- 사용 가능한 시스템 저장 공간과 실제 메모리를 표시하며 Windows에서는 C 드라이브 여유 공간을 표시합니다.
- 실시간 할당량 값을 안정적으로 유지하고 계정 전환 후 이전 계정 데이터가 표시되지 않도록 합니다.
- 독립적으로 실행되며 로컬 Codex 할당량 데이터를 읽습니다.
- 창 위치, 테마, 항상 위 상태 저장.
- 공통 Flutter 데스크톱 코드가 macOS와 Windows의 HUD, Dock 또는 트레이 아이콘, 메뉴와 수명 주기를 함께 관리합니다.
- 앱 인스턴스와 할당량 창을 각각 하나로 제한하며, 숨긴 뒤 메뉴 막대 또는 시스템 트레이에서 다시 표시할 수 있습니다.
- Windows에서는 작업 표시줄 항목을 유지하고 macOS에서는 고정할 때 상태 막대 창 레벨을 사용합니다.
- 두 플랫폼에서 동일한 macOS 스타일 벡터 아이콘을 사용합니다.
- 메뉴 막대 또는 시스템 트레이에서 업데이트, 제거, 언어 전환을 지원.
- GitHub에 새 릴리스가 있으면 버전 표시 옆에 작은 빨간 점을 표시.
- 다크 모드와 라이트 모드 지원.
- 시스템 언어 자동 적용.

## 설치

[Quota Bubble 공식 웹사이트](https://htmlpreview.github.io/?https://github.com/itzhaolei/codex-usage-widget/blob/main/public/index.html?v=20260926-4)의 기본 다운로드 버튼을 클릭하세요. macOS 또는 Windows를 감지해 Release 페이지를 거치지 않고 최신 GUI 설치 프로그램을 바로 다운로드합니다.

### macOS

macOS 13 이상. `macOS-Installer.zip`의 압축을 풀고 `Install Quota Bubble.app`을 여세요. Node.js, npm, 별도 Codex CLI, Xcode 또는 명령줄 도구가 필요 없습니다. Codex에 로그인되어 있고 `~/.codex/auth.json`이 생성되어 있어야 합니다.

### Windows

Windows 10 이상. `Windows-Setup.exe`를 열고 GUI 설치 마법사를 따르세요. 설치 후 바탕 화면에 Quota Bubble 실행 바로 가기가 자동으로 생성됩니다. PowerShell, Node.js, 터미널 명령 또는 별도 .NET 런타임이 필요 없습니다.

## 제거

macOS에서는 메뉴 막대의 Quota Bubble 메뉴에서 **제거**, Windows에서는 **설정 > 앱 > 설치된 앱**을 사용하세요.

## 개인 정보

이 플러그인은 로컬에서 실행됩니다. 데스크톱 앱은 `~/.codex/auth.json`의 현재 Codex token을 메모리에서만 읽어 해당 계정의 할당량, 잔액, 요금제 및 재설정 횟수를 Codex 백엔드에 요청합니다. Token은 스냅샷에 기록되지 않으며 저장소에도 개인 인증 정보나 계정 데이터가 포함되지 않습니다.
