import Foundation
import MCP
import IOSControlClient

struct ScreenshotTool: MCPTool {
    static let name = "screenshot"

    static let description = "Captures a screenshot of the current screen. Use to check screen layout or visual state. Use get_ui_tree to interact with UI elements."

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
