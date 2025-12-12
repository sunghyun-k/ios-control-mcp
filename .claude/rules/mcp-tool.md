---
paths: MCPServer/Sources/MCPServer/Tools/**/*.swift
---

# MCP 도구 추가

## 체크리스트

1. **Tool**: `Tools/`에 `MCPToolDefinition` 구현
2. **Registry**: `ToolRegistry.swift`의 `toolTypes` 배열에 추가
3. (필요시) **iOSAutomation**: Facade 메서드 추가

## Tool 템플릿

```swift
enum FooTool: MCPToolDefinition {
    static let name = "foo"  // snake_case
    static let description = "English description for LLM"  // 영어 필수!
    static let parameters: [ToolParameter] = [
        ToolParameter(name: "bar", type: .string, description: "..."),
    ]

    static func execute(
        arguments: [String: Value]?,
        automation: iOSAutomation,
    ) async throws -> [Tool.Content] {
        let args = arguments ?? [:]
        let bar = try args.string("bar")
        // ...
        return [.text("Done")]  // 응답도 영어
    }
}
```

## 주의사항

- `name`: snake_case (예: `get_ui_snapshot`)
- `description`, 응답 메시지: **영어 필수** (LLM이 이해해야 함)
- 파라미터 추출: `args.string()`, `args.optionalString()`, `args.double()` 등
- enum 파라미터: `enumValues` 지정
