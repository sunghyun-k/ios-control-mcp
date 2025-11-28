# ios-control-mcp

iOS 시뮬레이터 자동화를 위한 MCP(Model Context Protocol) 서버입니다. LLM이 iOS 시뮬레이터와 상호작용할 수 있게 해줍니다.

## 주요 기능

- iOS 시뮬레이터 UI 요소 탐색 및 조작
- 탭, 스와이프, 텍스트 입력 등 제스처 자동화
- 스크린샷 캡처
- 앱 실행 및 관리

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
