import Foundation
import MCP

let instructions = """
iOS 시뮬레이터 및 실제 기기를 자동화하는 도구입니다.

## 기본 흐름
1. get_ui_tree로 현재 화면의 UI 요소 확인
2. tap, input_text 등으로 조작
3. 필요시 screenshot으로 결과 확인

## 주요 팁
- 시뮬레이터는 자동 선택됩니다. list_devices와 select_device는 실제 기기가 여러 대일 때만 필요합니다.
- 키보드가 열려 있으면 요소가 가려질 수 있습니다. 키보드 위쪽을 탭하거나 스크롤하여 닫은 후 get_ui_tree를 호출하세요.
- tap으로 요소를 찾지 못하면 get_ui_tree에서 라벨을 다시 확인하거나, show_coords: true로 좌표를 확인 후 tap_coordinate를 사용하세요.
"""

let server = await Server(
    name: "ios-control",
    version: appVersion,
    instructions: instructions,
    capabilities: .init(tools: .init())
)
.withMethodHandler(ListTools.self) { _ in
    ListTools.Result(tools: ToolRegistry.allTools)
}
.withMethodHandler(CallTool.self) { params in
    do {
        let content = try await ToolRegistry.handle(name: params.name, arguments: params.arguments)
        return CallTool.Result(content: content)
    } catch {
        return CallTool.Result(content: [.text("Error: \(error.localizedDescription)")], isError: true)
    }
}

let transport = StdioTransport()
try await server.start(transport: transport)

await server.waitUntilCompleted()
