import Foundation
import MCP
import IOSControlClient

struct ListAppsTool: MCPTool {
    static let name = "list_apps"

    static let description = "시뮬레이터에 설치된 앱들의 번들 ID 목록을 반환합니다."

    static let inputSchema: Value = .object([
        "type": .string("object"),
        "properties": .object([:])
    ])

    typealias Arguments = EmptyArgs

    static func execute(args: EmptyArgs, client: IOSControlClient) async throws -> [Tool.Content] {
        let response = try await client.listApps()
        let list = response.bundleIds.joined(separator: "\n")
        return [.text(list)]
    }
}
