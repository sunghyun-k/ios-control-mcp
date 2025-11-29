import Foundation
import MCP
import IOSControlClient

struct LaunchAppTool: MCPTool {
    static let name = "launch_app"

    static let description = "Launches an app by bundle ID. Use list_apps to find bundle IDs."

    static let inputSchema: Value = .object([
        "type": .string("object"),
        "properties": .object([
            "bundle_id": .object(["type": .string("string"), "description": .string("Bundle ID of the app to launch")])
        ]),
        "required": .array([.string("bundle_id")])
    ])

    typealias Arguments = BundleIdArgs

    static func execute(args: BundleIdArgs, client: any AgentClient) async throws -> [Tool.Content] {
        try await client.launchApp(bundleId: args.bundleId)
        return [.text("launched \(args.bundleId)")]
    }
}
