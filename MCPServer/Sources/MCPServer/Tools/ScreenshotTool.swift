import Foundation
import MCP
import IOSControlClient

struct ScreenshotTool: MCPTool {
    static let name = "screenshot"

    static let description = "현재 화면의 스크린샷을 캡처합니다. 화면 레이아웃이나 시각적 상태를 확인할 때 사용하세요. UI 요소와 상호작용하려면 get_ui_tree를 사용하세요."

    static let inputSchema: Value = .object([
        "type": .string("object"),
        "properties": .object([:])
    ])

    typealias Arguments = EmptyArgs

    static func execute(args: EmptyArgs, client: any AgentClient) async throws -> [Tool.Content] {
        let data = try await client.screenshot()
        let base64 = data.base64EncodedString()
        return [.image(data: base64, mimeType: "image/png", metadata: nil)]
    }
}
