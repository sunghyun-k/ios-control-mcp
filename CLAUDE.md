# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

iOS 시뮬레이터 및 실제 iOS 기기 자동화 MCP 서버. XCTest 프레임워크의 특별한 권한을 활용하여 iOS 디바이스 내에서 HTTP 서버를 실행하고, MCP 프로토콜로 AI 에이전트가 디바이스를 조작할 수 있게 함.

## 프로젝트 구조

```
ios-control-mcp/
├── MCPServer/                          # MCP 서버 (macOS Swift 패키지)
│   └── Sources/
│       ├── MCPServer/                  # MCP 서버 메인 (진입점: main.swift)
│       │   └── Tools/                  # MCP 도구 구현
│       ├── IOSControlClient/           # iOS 기기 통신 클라이언트
│       │   └── Peertalk/               # USB 통신 (usbmuxd 프로토콜)
│       └── Playground/                 # 클라이언트 테스트용 CLI
│
├── AutomationServer/                   # iOS 자동화 에이전트 (Xcode 프로젝트)
│   └── AutomationServerTests/          # XCTest 번들 (진입점: AutomationServerTests.swift)
│       ├── Server/                     # FlyingFox HTTP 서버
│       ├── Handlers/                   # HTTP 핸들러 (tap, swipe, screenshot 등)
│       └── XCTest/                     # XCTest 프라이빗 API 래퍼
│
├── Common/                             # 공유 모델 (iOS + macOS)
│   └── Sources/Common/                 # 요청/응답 모델, AXElement
│
├── Makefile                            # 빌드 자동화
└── package.json                        # npm 패키지 설정
```

## 주요 명령어

```bash
make mcp-run              # MCP 서버 빌드 및 실행
make agent-run            # AutomationServer 빌드 및 실행 (시뮬레이터)
make device-agent-run DEVICE_UDID=<UDID> TEAM=<TEAM_ID>  # 실기기
make playground           # 클라이언트 테스트
make release              # 릴리즈 빌드 (Universal)
make clean                # 정리
```

## 아키텍처

```
LLM ◄─── MCP ───► MCPServer (macOS) ◄─── HTTP ───► AutomationServer (iOS XCTest)
```

- **MCPServer**: MCP 프로토콜로 LLM과 통신, HTTP로 iOS 기기의 AutomationServer와 통신
- **AutomationServer**: XCTest 번들로 실행되어 터치/스와이프 이벤트 합성, 스크린샷 캡처 등 수행

### 핵심 진입점

| 컴포넌트 | 진입점 |
|---------|--------|
| MCP 서버 | `MCPServer/Sources/MCPServer/main.swift` |
| iOS 에이전트 | `AutomationServer/AutomationServerTests/AutomationServerTests.swift` |
| 이벤트 합성 | `AutomationServer/AutomationServerTests/XCTest/RunnerDaemonProxy.swift` |

## 의존성

- **MCPServer**: `swift-sdk` (MCP 프로토콜)
- **AutomationServer**: `FlyingFox` (HTTP 서버)

## Instructions

- Always answer in 한국어.
- 작업이 완료되면 커밋 수행.
