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
- **list_devices** - 연결된 iOS 기기 목록 조회 (실제 기기 연결 시에만 필요)
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
> "현재 화면의 UI 트리 보여줘"

**앱 네비게이션:**
> "설정 앱 열고 일반 > 정보로 이동해줘"
> "Safari 실행해서 apple.com으로 가줘"

**UI 조작:**
> "'로그인' 버튼 눌러줘"
> "이메일 입력란에 'hello@example.com' 입력해줘"
> "'개인정보' 옵션 찾을 때까지 아래로 스크롤해줘"

**복합 플로우:**
> "온보딩 플로우 테스트해줘: 인트로 스킵하고, 테스트 데이터로 계정 만들고, 홈 화면 나오는지 확인해줘"

## 트러블슈팅

### 시뮬레이터

| 에러 | 해결 방법 |
|------|----------|
| "사용 가능한 iPhone 시뮬레이터가 없습니다" | Xcode 설치 후 `xcodebuild -downloadPlatform iOS` 실행 |
| "AutomationServer 앱을 찾을 수 없습니다" | 처음 실행 시 자동으로 빌드됩니다. Xcode가 설치되어 있는지 확인하세요. |
| "시뮬레이터 부팅 실패" | Xcode → Settings → Platforms에서 iOS 시뮬레이터가 설치되어 있는지 확인 |

### 실제 기기

| 에러 | 해결 방법 |
|------|----------|
| "Physical device requires Apple Developer Team ID" | MCP 설정의 `env`에 `IOS_CONTROL_TEAM_ID` 추가 |
| "Xcode project not found" | Xcode가 설치되어 있는지 확인하세요 |
| 빌드 실패 (사이닝 에러) | 1) Team ID가 올바른지 확인<br>2) 기기가 USB로 연결되어 있는지 확인<br>3) Xcode에서 해당 기기로 아무 앱이나 한 번 빌드하여 프로비저닝 설정 |
| "신뢰하지 않는 개발자" | 기기의 설정 → 일반 → VPN 및 기기 관리에서 개발자 앱 신뢰 |
| 기기가 목록에 안 보임 | 1) USB 케이블 재연결<br>2) "이 컴퓨터를 신뢰" 팝업 확인<br>3) 개발자 모드 활성화 확인 |

### 공통

| 에러 | 해결 방법 |
|------|----------|
| "No iOS device or simulator available" | Xcode 설치 및 시뮬레이터 다운로드, 또는 실제 기기 USB 연결 |
| "서버가 시작되지 않았습니다" | Agent 앱이 기기/시뮬레이터에서 정상 실행 중인지 확인. 재시도하거나 기기를 재부팅하세요. |

## UI 트리 형식

`get_ui_tree` 도구는 LLM 토큰 효율성을 위해 최적화된 간결한 YAML 형식을 반환합니다:

```yaml
- Application "설정":
  - NavBar:
    - Text "설정"
  - CollectionView:
    - Cell:
      - Button "일반":
        - row:
          - Image
          - Text "일반"
          - Image
    - Cell:
      - Button "개인정보 보호":
        - row:
          - Image
          - Text "개인정보 보호"
```

**주요 특징:**
- **라벨 기반 탭**: `tap` 도구에 요소 라벨만 전달하면 됩니다 (예: `tap("일반")`) - 좌표 불필요
- **중복 라벨 처리**: 동일한 라벨을 가진 요소가 여러 개면 `"라벨"#0`, `"라벨"#1` 형식으로 인덱싱
- **행 그룹화**: 가로로 정렬된 요소들은 `row:` 아래에 그룹화되어 가독성 향상
- **화면 밖 요소 필터링**: 보이는 화면 밖의 요소는 자동으로 숨김 처리
- **키보드 인식**: 키보드 요소와 키보드에 가려진 콘텐츠는 필터링
- **메타데이터 지원**: 값과 플레이스홀더는 `/value:`, `/placeholder:` 형식으로 표시

이 형식은 UI 자동화에 필요한 모든 정보를 유지하면서 raw 접근성 트리 대비 토큰 사용량을 크게 줄여줍니다.

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
