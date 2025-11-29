import Foundation
import MCP
import IOSControlClient

struct GoHomeTool: MCPTool {
    static let name = "go_home"

    static let description = "Goes to the home screen."

    static let inputSchema: Value = .object([
        "type": .string("object"),
        "properties": .object([:])
    ])

    typealias Arguments = EmptyArgs

    static func execute(args: EmptyArgs, client: any AgentClient) async throws -> [Tool.Content] {
        try await client.goHome()
        return [.text("pressed home button")]
    }
}
