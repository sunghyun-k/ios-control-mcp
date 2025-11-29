import Foundation
import MCP
import IOSControlClient

struct GetUITreeTool: MCPTool {
    static let name = "get_ui_tree"

    static let description = "Returns the UI element tree of the current screen. Use to find labels for tap, drag, etc. If keyboard is open, elements may be hidden - tap above keyboard or scroll to dismiss it first."

    static let inputSchema: Value = .object([
        "type": .string("object"),
        "properties": .object([
            "show_coords": .object(["type": .string("boolean"), "description": .string("Whether to show coordinates. Default false. Only set to true when using tap_coordinate.")])
        ])
    ])

    typealias Arguments = GetUITreeArgs

    static func execute(args: GetUITreeArgs, client: any AgentClient) async throws -> [Tool.Content] {
        let appBundleId = try await client.foregroundApp().bundleId
        let showCoords = args.showCoords ?? false

        let response = try await client.tree(appBundleId: appBundleId)
        return [.text(TreeFormatter.format(response.tree, showCoords: showCoords))]
    }
}
