import Foundation
import MCP
import IOSControlClient

struct GetForegroundAppTool: MCPTool {
    static let name = "get_foreground_app"

    static let description = "현재 포그라운드에 있는 앱의 번들 ID를 반환합니다."

    static let inputSchema: Value = .object([
        "type": .string("object"),
        "properties": .object([:])
    ])

    typealias Arguments = EmptyArgs

    static func execute(args: EmptyArgs, client: IOSControlClient) async throws -> [Tool.Content] {
        let response = try await client.foregroundApp()
        return [.text(response.bundleId ?? "")]
    }
}
