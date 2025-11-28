# ios-control-mcp

iOS 시뮬레이터 자동화를 위한 MCP(Model Context Protocol) 서버입니다. LLM이 iOS 시뮬레이터와 상호작용할 수 있게 해줍니다.

## 주요 기능

### UI 조작
- **tap** - 라벨로 UI 요소를 찾아 탭 (롱프레스 지원)
- **tap_coordinate** - 좌표로 직접 탭
- **swipe** - 스와이프 제스처
- **scroll** - 화면 스크롤
- **pinch** - 핀치 줌 인/아웃 (지도, 이미지 확대/축소)
- **input_text** - 텍스트 입력

### 앱 관리
- **launch_app** - 번들 ID로 앱 실행
- **terminate_app** - 앱 강제 종료
- **list_apps** - 설치된 앱 목록 조회
- **get_foreground_app** - 현재 포그라운드 앱 확인
- **go_home** - 홈 화면으로 이동

### 화면 정보
- **get_ui_tree** - UI 요소 트리 조회
- **screenshot** - 스크린샷 캡처 (PNG)

### 유틸리티
- **open_url** - URL 열기 (딥링크, Safari)
- **get_pasteboard** - 클립보드 읽기
- **set_pasteboard** - 클립보드 쓰기

## 요구 사항

- macOS
- Xcode (iOS 시뮬레이터 포함)
- Node.js 18 이상

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

## 라이선스

MIT
