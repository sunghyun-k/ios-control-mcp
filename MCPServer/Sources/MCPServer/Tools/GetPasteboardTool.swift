import Foundation
import MCP
import IOSControlClient

struct GetPasteboardTool: MCPTool {
    static let name = "get_pasteboard"

    static let description = "시뮬레이터 클립보드의 내용을 가져옵니다."

    static let inputSchema: Value = .object([
        "type": .string("object"),
        "properties": .object([:])
    ])

    typealias Arguments = EmptyArgs

    static func execute(args: EmptyArgs, client: any AgentClient) async throws -> [Tool.Content] {
        let response = try await client.getPasteboard()
        return [.text(response.content ?? "")]
    }
}
