import Foundation
import MCP
import IOSControlClient

struct OpenURLTool: MCPTool {
    static let name = "open_url"

    static let description = "URL을 엽니다. 딥링크나 웹 URL을 Safari에서 열 수 있습니다."

    static let inputSchema: Value = .object([
        "type": .string("object"),
        "properties": .object([
            "url": .object(["type": .string("string"), "description": .string("열 URL (예: https://example.com 또는 myapp://path)")])
        ]),
        "required": .array([.string("url")])
    ])

    typealias Arguments = URLArgs

    static func execute(args: URLArgs, client: IOSControlClient) async throws -> [Tool.Content] {
        try await client.openURL(args.url)
        return [.text("opened \(args.url)")]
    }
}
