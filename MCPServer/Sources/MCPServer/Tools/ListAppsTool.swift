import Foundation
import MCP
import IOSControlClient

struct ListAppsTool: MCPTool {
    static let name = "list_apps"

    static let description = "Returns a list of installed apps' bundle IDs. Use to find bundle IDs for launch_app."

    static let inputSchema: Value = .object([
        "type": .string("object"),
        "properties": .object([:])
    ])

    typealias Arguments = EmptyArgs

    static func execute(args: EmptyArgs, client: any AgentClient) async throws -> [Tool.Content] {
        let response = try await client.listApps()
        let list = response.bundleIds.joined(separator: "\n")
        return [.text(list)]
    }
}
