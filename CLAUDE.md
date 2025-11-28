# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

iOS 시뮬레이터 자동화 MCP 서버. XCTest 프레임워크의 특별한 권한을 활용하여 시뮬레이터 내에서 HTTP 서버를 실행하고, MCP 프로토콜로 AI 에이전트가 시뮬레이터를 조작할 수 있게 함.

## 프로젝트 구조

```
ios-control-mcp/
├── MCPServer/           # MCP 서버 Swift 패키지
│   └── Sources/
│       ├── MCPServer/       # MCP 서버 실행 파일
│       ├── IOSControlClient/ # SimulatorAgent HTTP 클라이언트 + simctl 래퍼
│       └── Playground/      # IOSControlClient 테스트용 실행 파일
├── SimulatorAgent/      # iOS 시뮬레이터 에이전트 (Xcode 프로젝트)
│   └── SimulatorAgentTests/ # XCTest 번들 (HTTP 서버 + UI 조작)
│       ├── Server/          # FlyingFox HTTP 서버
│       ├── Handlers/        # HTTP 요청 처리기 (tap, swipe, screenshot 등)
│       └── XCTest/          # XCTest 프라이빗 API 래퍼
└── Common/              # 공유 코드 (요청/응답 모델)
```

## 주요 명령어

- `make mcp`: MCP 서버 빌드
- `make mcp-run`: MCP 서버 빌드 및 실행
- `make agent`: SimulatorAgent 빌드
- `make agent-run`: SimulatorAgent 빌드 및 실행
- `make playground`: Playground 실행 (IOSControlClient 테스트용)
- `make clean`: 빌드 결과물 정리

## Playground 사용법

MCP 서버 없이 IOSControlClient를 직접 테스트:

1. SimulatorAgent 실행 (별도 터미널): `make agent-run`
2. Playground 실행: `make playground`

`MCPServer/Sources/Playground/main.swift` 파일을 수정하여 테스트 코드 작성.

## 아키텍처

### SimulatorAgent (XCTest Hack)

iOS 시뮬레이터에서 일반 앱은 네트워크 바인딩이 제한되지만, XCTest는 특별한 권한을 가짐. SimulatorAgent는 XCTest 번들로 구성되어 이 권한을 활용.

- `testRunServer()` 테스트가 실행되면 FlyingFox HTTP 서버(`127.0.0.1:22087`)가 무한 루프로 유지됨.
- `RunnerDaemonProxy`: Objective-C 런타임 리플렉션으로 XCTest 백엔드에 접근하여 터치/스와이프 이벤트 합성.
- 공개 XCTest API: `XCUIApplication`(앱 실행), `XCUIScreen`(스크린샷), `XCUIDevice`(홈 버튼).

### UDID 기반 시뮬레이터 식별

- SimulatorAgent는 `SIMULATOR_UDID` 환경변수로 자신이 실행 중인 시뮬레이터 UDID를 알 수 있음.
- `/status` 응답에 `udid` 필드가 포함되어, 클라이언트가 정확한 시뮬레이터 대상으로 simctl 명령 실행 가능.
- `list_apps`는 Agent에서 UDID를 받아 `simctl listapps <udid>`로 호출.

## Instructions

- Always answer in 한국어.
- 작업이 완료되면 커밋 수행.
