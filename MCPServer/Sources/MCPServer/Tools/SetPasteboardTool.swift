import Foundation
import MCP
import IOSControlClient

struct SetPasteboardTool: MCPTool {
    static let name = "set_pasteboard"

    static let description = "시뮬레이터 클립보드에 텍스트를 설정합니다."

    static let inputSchema: Value = .object([
        "type": .string("object"),
        "properties": .object([
            "content": .object(["type": .string("string"), "description": .string("클립보드에 설정할 텍스트")])
        ]),
        "required": .array([.string("content")])
    ])

    typealias Arguments = ContentArgs

    static func execute(args: ContentArgs, client: IOSControlClient) async throws -> [Tool.Content] {
        try await client.setPasteboard(args.content)
        return [.text("set pasteboard to \"\(args.content)\"")]
    }
}
