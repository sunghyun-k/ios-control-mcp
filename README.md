# ios-control-mcp

iOS 시뮬레이터 및 실제 iOS 기기를 자동화하기 위한 MCP(Model Context Protocol) 서버입니다. Claude와 같은 LLM이 iOS 디바이스와 상호작용할 수 있게 해줍니다.

## 주요 기능

### 기기 관리
- **list_devices** - 연결된 iOS 기기 목록 조회
- **select_device** - 조작할 기기 선택 (UDID 지정 또는 자동 선택)

### UI 조작
- **tap** - 라벨로 UI 요소를 찾아 탭 (롱프레스 지원)
- **tap_coordinate** - 좌표로 직접 탭
- **swipe** - 스와이프 제스처
- **scroll** - 화면 스크롤 (방향 기반)
- **drag** - UI 요소 드래그 (리스트 재정렬 등)
- **pinch** - 핀치 줌 인/아웃 (지도, 이미지 확대/축소)
- **input_text** - 텍스트 입력

### 앱 관리
- **launch_app** - 번들 ID로 앱 실행
- **list_apps** - 설치된 앱 목록 조회
- **go_home** - 홈 화면으로 이동

### 화면 정보
- **get_ui_tree** - UI 접근성 트리 조회 (YAML 형식, 좌표 표시 옵션)
- **screenshot** - 스크린샷 캡처 (PNG)

## 요구 사항

- macOS 13 이상
- Xcode (iOS 시뮬레이터 포함)
- Node.js 18 이상
- 실기기 지원 시: Apple Developer Team ID (무료/유료)

## 설치

**Standard config** - 대부분의 MCP 클라이언트에서 동작합니다:

```json
{
  "mcpServers": {
    "ios-control": {
      "command": "npx",
      "args": [
        "-y",
        "ios-control-mcp"
      ]
    }
  }
}
```

<details>
<summary>Claude Code</summary>

```bash
claude mcp add ios-control -- npx -y ios-control-mcp
```

</details>

<details>
<summary>Claude Desktop</summary>

[MCP 설치 가이드](https://modelcontextprotocol.io/quickstart/user)를 따라 위의 Standard config를 사용하세요.

</details>

<details>
<summary>Cursor</summary>

`Cursor Settings` → `MCP` → `Add new MCP Server`로 이동합니다. 이름을 지정하고, `command` 타입으로 `npx -y ios-control-mcp` 명령어를 입력합니다.

</details>

<details>
<summary>VS Code</summary>

VS Code CLI로 설치:

```bash
code --add-mcp '{"name":"ios-control","command":"npx","args":["-y","ios-control-mcp"]}'
```

또는 [MCP 설치 가이드](https://code.visualstudio.com/docs/copilot/chat/mcp-servers#_add-an-mcp-server)를 따라 위의 Standard config를 사용하세요.

</details>

<details>
<summary>Windsurf</summary>

[Windsurf MCP 문서](https://docs.windsurf.com/windsurf/cascade/mcp)를 따라 위의 Standard config를 사용하세요.

</details>

## 아키텍처

이 프로젝트는 두 개의 주요 컴포넌트로 구성됩니다:

1. **MCP 서버** (macOS) - LLM과 통신하는 MCP 프로토콜 서버
2. **AutomationServer** (iOS) - 시뮬레이터/실기기에서 실행되는 XCTest 기반 자동화 에이전트

```
┌─────────────┐     MCP      ┌─────────────┐    HTTP     ┌──────────────────┐
│     LLM     │◄────────────►│  MCP Server │◄───────────►│ AutomationServer │
│  (Claude)   │   Protocol   │   (macOS)   │  (localhost)│    (iOS XCTest)  │
└─────────────┘              └─────────────┘             └──────────────────┘
```

XCTest 프레임워크의 특별한 권한을 활용하여 시뮬레이터 내에서 HTTP 서버를 실행하고, Objective-C 런타임 리플렉션으로 터치/스와이프 이벤트를 합성합니다.

## 개발

### 빌드 명령어

```bash
# MCP 서버
make mcp              # 빌드
make mcp-run          # 빌드 및 실행

# AutomationServer (시뮬레이터)
make agent            # 빌드
make agent-run        # 빌드 및 실행

# AutomationServer (실기기)
make device-agent TEAM=<TEAM_ID>
make device-agent-run DEVICE_UDID=<UDID> TEAM=<TEAM_ID>

# 테스트용 Playground
make playground

# 정리
make clean
```

### Playground

MCP 서버 없이 클라이언트 라이브러리를 직접 테스트할 수 있습니다:

1. AutomationServer 실행 (별도 터미널): `make agent-run`
2. Playground 실행: `make playground`

`MCPServer/Sources/Playground/main.swift` 파일을 수정하여 테스트 코드를 작성합니다.

## 라이선스

MIT
