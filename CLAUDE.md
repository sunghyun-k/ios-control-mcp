# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

- ios-control: iOS 시뮬레이터 자동화 MCP

## 프로젝트 구조

- MCPServer: MCP 서버 Swift 패키지. 3개의 타겟으로 구성.
  - MCPServer: MCP 서버 실행 파일.
  - IOSControlClient: SimulatorAgent HTTP 클라이언트 및 simctl 래퍼 라이브러리.
  - Playground: IOSControlClient 테스트용 실행 파일.
- SimulatorAgent: iOS 시뮬레이터 조작을 위한 Xcode 프로젝트. UITest를 통해 시뮬레이터를 조작하는 hack을 적용. HTTP 서버를 실행하여 MCP 서버와 통신.
- Common: MCPServer와 SimulatorAgent의 HTTP 요청, 응답 공통 코드.

## 주요 명령어

- `make mcp`: MCP 서버 빌드.
- `make mcp-run`: MCP 서버 빌드 및 실행.
- `make agent`: SimulatorAgent 빌드.
- `make agent-run`: SimulatorAgent 빌드 및 실행.
- `make playground`: Playground 실행 (IOSControlClient 테스트용).
- `make clean`: 빌드 결과물 정리.

## Playground 사용법

Playground는 MCP 서버 없이 IOSControlClient를 직접 테스트할 수 있는 도구입니다.

1. SimulatorAgent 실행 (별도 터미널): `make agent-run`
2. Playground 실행: `make playground`

`MCPServer/Sources/Playground/main.swift` 파일을 수정하여 테스트 코드 작성:

```swift
import Foundation
import IOSControlClient

let client = IOSControlClient()

// 앱 목록 조회
let apps = try await client.listApps()
print(apps.bundleIds)

// 앱 실행
try await client.launchApp(bundleId: "com.apple.Preferences")
```

## 아키텍처 노트

- SimulatorAgent는 `SIMULATOR_UDID` 환경변수로 자신이 실행 중인 시뮬레이터 UDID를 알 수 있음.
- `/status` 응답에 `udid` 필드가 포함되어 있어, 클라이언트가 정확한 시뮬레이터를 대상으로 simctl 명령 실행 가능.
- `list_apps`는 Agent에서 UDID를 받아 `simctl listapps <udid>`로 호출.
- 그 외 도구들(tap, swipe, screenshot 등)은 SimulatorAgent HTTP 서버를 통해 동작.

## Instructions

- Always answer in 한국어.
- 작업이 완료되면 커밋 수행.
