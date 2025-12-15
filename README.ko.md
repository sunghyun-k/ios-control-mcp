# ios-control-mcp

[![npm version](https://img.shields.io/npm/v/ios-control-mcp)](https://www.npmjs.com/package/ios-control-mcp)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)

[English](README.md)

iOS 시뮬레이터 및 실제 iOS 기기를 자동화하기 위한 MCP(Model Context Protocol) 서버입니다. Claude와 같은 LLM이 iOS 디바이스와 상호작용할 수 있게 해줍니다.

https://github.com/user-attachments/assets/4284357b-6b6e-4e6a-a81c-e5976052be51

## 빠른 시작

30초 안에 시작하기:

1. MCP 클라이언트 설정에 추가:
   ```json
   {
     "mcpServers": {
       "ios-control": {
         "command": "npx",
         "args": ["-y", "ios-control-mcp"]
       }
     }
   }
   ```

2. Claude에게 요청: *"iOS 시뮬레이터 스크린샷 찍어줘"*

끝! 이제 Claude가 iOS 시뮬레이터를 제어할 수 있습니다. 자세한 설정은 [설치](#설치) 섹션을 참고하세요.

## 주요 기능

### 기기 관리

- **list_devices** - 연결된 iOS 기기 목록 조회 (시뮬레이터 및 실제 기기)
- **select_device** - UDID로 조작할 기기 선택

### 화면 정보

- **get_ui_snapshot** - 모든 포그라운드 앱의 UI 요소 트리 조회
- **screenshot** - 현재 화면 스크린샷 캡처

### UI 조작

- **tap** - 라벨로 UI 요소 탭
- **type_text** - 텍스트 입력 (특정 요소에 입력 가능)
- **swipe** - 스와이프 제스처
- **drag** - 라벨로 요소를 다른 요소로 드래그

### 앱 및 기기 제어

- **launch_app** - 번들 ID로 앱 실행
- **press_button** - 하드웨어 버튼 누르기 (home, volumeUp, volumeDown)

## 요구 사항

- macOS 13 이상
- Xcode (iOS 시뮬레이터 포함)
- Node.js 18 이상
- 실기기 지원 시: Apple Developer Team ID (무료/유료)

## 설치

### 시뮬레이터 사용 (기본)

시뮬레이터는 별도 설정 없이 바로 사용할 수 있습니다.

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

실기기 사용 시, Team ID 환경변수를 추가합니다:

```bash
claude mcp add ios-control -e IOS_CONTROL_TEAM_ID=YOUR_TEAM_ID -- npx -y ios-control-mcp
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

### 실제 iOS 기기 사용

실제 iOS 기기를 사용하려면 Apple Developer Team ID가 필요합니다. 무료 Apple ID로도 가능합니다.

#### 1. Team ID 찾기

터미널에서 다음 명령어로 Team ID를 확인합니다:

```bash
security find-identity -v -p codesigning
```

출력 예시:
```
1) ABCDEF1234567890... "Apple Development: your@email.com (XXXXXXXXXX)"
```

괄호 안의 10자리 문자열(예: `XXXXXXXXXX`)이 Team ID입니다.

> **Team ID가 없다면?** Xcode에서 아무 프로젝트나 열고, 본인 Apple ID로 로그인한 뒤 한 번이라도 기기에 앱을 빌드하면 자동으로 생성됩니다.

#### 2. MCP 설정에 Team ID 추가

```json
{
  "mcpServers": {
    "ios-control": {
      "command": "npx",
      "args": ["-y", "ios-control-mcp"],
      "env": {
        "IOS_CONTROL_TEAM_ID": "YOUR_TEAM_ID"
      }
    }
  }
}
```

#### 3. 기기 준비

1. **개발자 모드 활성화**: 설정 → 개인정보 보호 및 보안 → 개발자 모드 → 활성화 (iOS 16+)
2. **USB 연결**: Mac에 기기를 USB로 연결하고 "이 컴퓨터를 신뢰하시겠습니까?" 팝업에서 신뢰 선택
3. **첫 실행 시**: 기기에 앱 설치 후 "신뢰하지 않는 개발자" 경고가 뜨면, 설정 → 일반 → VPN 및 기기 관리에서 개발자 앱을 신뢰하도록 설정

## 사용 예시

Claude에게 요청할 수 있는 것들:

**스크린샷 & UI 검사:**
> "현재 화면 스크린샷 찍어줘"
> "UI 스냅샷 보여줘"

**앱 네비게이션:**
> "설정 앱 열어줘"
> "Safari 실행해줘"

**UI 조작:**
> "'로그인' 버튼 눌러줘"
> "이메일 입력란에 'hello@example.com' 입력해줘"
> "위로 스와이프해줘"

## 라이선스

MIT
