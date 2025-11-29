import Foundation
import MCP
import IOSControlClient

struct ScreenshotTool: MCPTool {
    static let name = "screenshot"

    static let description = "현재 화면의 스크린샷을 캡처합니다."

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
