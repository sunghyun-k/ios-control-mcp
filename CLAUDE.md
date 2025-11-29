# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

iOS 시뮬레이터 및 실제 iOS 기기 자동화 MCP 서버. XCTest 프레임워크의 특별한 권한을 활용하여 iOS 디바이스 내에서 HTTP 서버를 실행하고, MCP 프로토콜로 AI 에이전트가 디바이스를 조작할 수 있게 함.

## 프로젝트 구조

```
ios-control-mcp/
├── MCPServer/                      # MCP 서버 (macOS용 Swift 패키지)
│   └── Sources/
│       ├── MCPServer/              # MCP 서버 실행 파일
│       │   ├── main.swift          # StdioTransport 진입점
│       │   ├── ToolRegistry.swift  # 도구 레지스트리
│       │   ├── ToolProtocol.swift  # MCP 도구 프로토콜
│       │   ├── ToolArguments.swift # 도구 인자 정의
│       │   ├── Configuration.swift # 설정 상수
│       │   ├── AutomationServerRunner.swift # Agent 관리
│       │   └── Tools/              # 14개 MCP 도구 구현
│       ├── IOSControlClient/       # HTTP 클라이언트 라이브러리
│       │   ├── IOSControlClient.swift  # 시뮬레이터용 클라이언트
│       │   ├── USBHTTPClient.swift     # 실기기용 USB 클라이언트
│       │   ├── AgentClient.swift       # 공통 인터페이스
│       │   ├── DeviceManager.swift     # 기기 관리
│       │   ├── SimctlRunner.swift      # simctl 명령 실행
│       │   ├── DeviceCtlRunner.swift   # devicectl 명령 실행
│       │   └── Peertalk/               # usbmuxd 프로토콜
│       └── Playground/             # IOSControlClient 테스트용 CLI
│
├── AutomationServer/               # iOS 자동화 서버 (Xcode 프로젝트)
│   └── AutomationServerTests/      # XCTest 번들
│       ├── AutomationServerTests.swift # testRunServer() 진입점
│       ├── Server/                 # FlyingFox HTTP 서버
│       ├── Handlers/               # 10개 HTTP 핸들러
│       │   └── (StatusHandler, TapHandler, SwipeHandler,
│       │       TreeHandler, ScreenshotHandler, ForegroundAppHandler,
│       │       LaunchAppHandler, GoHomeHandler, PinchHandler, InputTextHandler)
│       └── XCTest/                 # XCTest 프라이빗 API 래퍼
│           └── RunnerDaemonProxy.swift # 터치/스와이프 이벤트 합성
│
├── Common/                         # 공유 코드 (iOS + macOS)
│   └── Sources/Common/
│       ├── Requests.swift          # HTTP 요청 모델
│       ├── Responses.swift         # HTTP 응답 모델
│       └── AXElement.swift         # Accessibility 요소 트리
│
├── Makefile                        # 빌드 자동화
└── package.json                    # npm 패키지 설정
```

## MCP 도구 목록

| 도구 | 설명 |
|------|------|
| `list_devices` | 연결된 iOS 기기 목록 |
| `select_device` | 조작할 기기 선택 |
| `tap` | 라벨로 UI 요소 탭 |
| `tap_coordinate` | 좌표로 탭 |
| `swipe` | 스와이프 제스처 |
| `scroll` | 화면 스크롤 |
| `drag` | UI 요소 드래그 |
| `pinch` | 핀치 줌 인/아웃 |
| `input_text` | 텍스트 입력 |
| `go_home` | 홈 화면 이동 |
| `get_ui_tree` | UI 접근성 트리 조회 |
| `screenshot` | 스크린샷 캡처 |
| `list_apps` | 설치된 앱 목록 |
| `launch_app` | 앱 실행 |

## 주요 명령어

```bash
# MCP 서버
make mcp              # 빌드
make mcp-run          # 빌드 및 실행

# AutomationServer (시뮬레이터)
make agent            # 빌드
make agent-run        # 빌드 및 실행 (UDID=<udid> 지정 가능)

# AutomationServer (실기기)
make device-agent TEAM=<TEAM_ID>
make device-agent-run DEVICE_UDID=<UDID> TEAM=<TEAM_ID>

# Playground (클라이언트 테스트)
make playground

# 릴리즈 빌드
make release          # Universal 바이너리
make release-arm64    # arm64 전용
make release-x64      # x86_64 전용

# 정리
make clean
```

## Playground 사용법

MCP 서버 없이 IOSControlClient를 직접 테스트:

1. AutomationServer 실행 (별도 터미널): `make agent-run`
2. Playground 실행: `make playground`

`MCPServer/Sources/Playground/main.swift` 파일을 수정하여 테스트 코드 작성.

## 아키텍처

### AutomationServer (XCTest Hack)

iOS 시뮬레이터/실기기에서 일반 앱은 네트워크 바인딩이 제한되지만, XCTest는 특별한 권한을 가짐.

- `testRunServer()` 테스트가 실행되면 FlyingFox HTTP 서버(`127.0.0.1:22087`)가 무한 루프로 유지됨
- `RunnerDaemonProxy`: Objective-C 런타임 리플렉션으로 XCTest 백엔드에 접근하여 터치/스와이프 이벤트 합성
- 공개 XCTest API: `XCUIApplication`(앱 실행), `XCUIScreen`(스크린샷), `XCUIDevice`(홈 버튼)

### 기기 선택 로직

```
선택된 기기 있음?
  ├─ YES → 해당 기기 사용
  └─ NO → 자동 선택:
      1. 부팅된 시뮬레이터
      2. 연결된 실기기
      3. 사용 가능한 시뮬레이터
```

### HTTP 서버 포트

- 기본 포트: `22087`
- 환경변수 `IOS_CONTROL_PORT`로 변경 가능

## 설정 상수

`MCPServer/Sources/MCPServer/Configuration.swift`:

```swift
agentHost: "127.0.0.1"
agentPort: 22087
httpTimeout: 30      // 초
serverStartTimeout: 60
simulatorBootTimeout: 60
```

## 주요 파일 위치

| 기능 | 파일 |
|------|------|
| MCP 진입점 | `MCPServer/Sources/MCPServer/main.swift` |
| 도구 레지스트리 | `MCPServer/Sources/MCPServer/ToolRegistry.swift` |
| 도구 구현 | `MCPServer/Sources/MCPServer/Tools/*.swift` |
| HTTP 클라이언트 | `MCPServer/Sources/IOSControlClient/IOSControlClient.swift` |
| 기기 관리 | `MCPServer/Sources/IOSControlClient/DeviceManager.swift` |
| HTTP 서버 | `AutomationServer/AutomationServerTests/Server/HTTPServer.swift` |
| 핸들러 | `AutomationServer/AutomationServerTests/Handlers/` |
| 이벤트 합성 | `AutomationServer/AutomationServerTests/XCTest/RunnerDaemonProxy.swift` |

## 의존성

- **MCPServer**: `swift-sdk` (MCP 프로토콜)
- **AutomationServer**: `FlyingFox` (HTTP 서버)

## Instructions

- Always answer in 한국어.
- 작업이 완료되면 커밋 수행.
